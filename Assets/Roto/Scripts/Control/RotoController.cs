using System.Collections;
using UnityEngine;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System;
using System.Linq;
using Debug = UnityEngine.Debug;

namespace Roto.Control
{
    /// <summary>
    /// Core class. Sends and recivies instructions from the chair.
    /// </summary>
    public class RotoController : MonoBehaviour
    {
        #region "STATE VARS"

        #region "Varibles"
        //[Header("---- Controlls ----")]
        private bool pedalLeft = false;
        private bool pedalRight = false;

        //[Header("Head tracker ----")]
        private bool headTrackerMode = false;
        private bool headTrackerOn = false;

        //[Header("---- Modes ----")]
        private bool cockpitMode = false;
        private bool freeMode = true;

        //[Header("---- Rumble ----")]
        private bool rumblePC = false;
        private bool rumbleAuto = true;

        //[Header("---- Special State ----")]
        private bool isSyncing = false;
        private readonly float shortPathBuffer = 1f;

        #endregion

        #region "Get varibles"
        /// <summary>
        /// Return if chair sync is in progress
        /// </summary>
        public bool IsSyncing
        {
            get { return isSyncing; }
        }

        /// <summary>
        /// return pedal press
        /// </summary>
        public bool PedalLeft
        {
            get { return pedalLeft; }
        }

        /// <summary>
        /// Return pedal press
        /// </summary>
        public bool PedalRight
        {
            get { return pedalRight; }
        }

        /// <summary>
        /// Return head tracker mode status
        /// </summary>
        public bool IsHeadTrackerModeOn
        {
            get { return headTrackerMode; }
        }

        /// <summary>
        /// Return head tracker status
        /// </summary>
        public bool IsHeadTrackerOn
        {
            get { return headTrackerOn; }
        }

        /// <summary>
        /// Return cockpit mode status
        /// </summary>
        public bool CockpitMode
        {
            get { return cockpitMode; }
        }

        /// <summary>
        /// Return free mode status
        /// </summary>
        public bool FreeMode
        {
            get { return freeMode; }
        }

        /// <summary>
        /// Return PC rumble mode status
        /// </summary>
        public bool PCMRumbleMode
        {
            get { return rumblePC; }
        }

        /// <summary>
        /// Return Auto rumble mode status
        /// </summary>
        public bool AutoRumbleMode
        {
            get { return rumbleAuto; }
        }

        #endregion
        #endregion

        #region "VIRTUAL OBJ"

        private string lastOutput = "";
        protected GameObject rotoVirtualTarget;
        /// <summary>
        /// Roto base target will use mimic functions to copy to roto rotation to the object and vice versa.
        /// Set only
        /// </summary>
        public GameObject RotoVirtualTarget
        {
            set { rotoVirtualTarget = value; }
        }

        protected GameObject vrHeadSet; // used for roto calibration

        /// <summary>
        /// Set only, assign vr headset to this var - used in roto sync update
        /// </summary>
        public GameObject VRHeadSet
        {
            set { vrHeadSet = value; }
        }

        #endregion

        #region "PROCESS VARS"

        // io vars --------
        private StreamWriter sw = null;
        private bool isConnected = false;
        // thread proccess vars ------
        private Thread processThread = null;
        string strAppName;
        //private string outStr;
        private static string commandFile;
        // proccess -------
        private Process process = null;
        // update vars ------
        private int currentAngle = 0;
        private readonly int fidgetBuffer = 8;

        #endregion

        #region "START UP"

        /// <summary>
        /// Check for previous roto connections
        /// </summary>
        private void Awake()
        {
            // allow control at 0.1 time interval
            Application.targetFrameRate = 10;

            strAppName = "rotoVRCmd.exe";

            // rotoVR command file path in streaming Assets
            commandFile = Path.Combine(Application.streamingAssetsPath, strAppName);

            // kill all the background running rotoVRCmd.exe to make sure only single instance is running.
            foreach (Process process in Process.GetProcessesByName(strAppName))
            {
                process.Kill();
            }
        }

        /// <summary>
        /// Connection start
        /// </summary>
        void Start()
        {
            processThread = new Thread(StreamLoop) { };
            processThread.Start();
            isConnected = true;
        }

        #endregion

        #region "PROCCESS CONNECTION"
        /// <summary>
        /// Send cmd to Roto chair
        /// </summary>
        /// <param name="cmd"></param>
        private void WriteCommand(string cmd)
        {
             //Debug.Log(cmd);
            if(isConnected)
            {
                if (sw != null)
                {
                    sw.WriteLine(cmd);
                    sw.Flush();
                }
            }
            
        }

        /// <summary>
        /// Loop and check connection thread
        /// </summary>
        private void StreamLoop()
        {
            process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    RedirectStandardInput = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    Arguments = "--redirect",
                    FileName = commandFile //  Application.dataPath +  "\\rotoVRCmd.exe"

                },
                EnableRaisingEvents = true
            };

            process.ErrorDataReceived += (sender, eventArgs) =>
            {
                Debug.Log("Error here >" + eventArgs.Data);
            };

            process.OutputDataReceived += (sender, eventArgs) =>
            {
            // Debug.Log("======>" + eventArgs.Data);

            if (eventArgs.Data.Length > 0)
                {

                    if (eventArgs.Data.StartsWith("{"))
                    {
                        lastOutput = eventArgs.Data;
                        pedalLeft = GetStringContainCheck(eventArgs.Data, 'L');
                        pedalRight = GetStringContainCheck(eventArgs.Data, 'R');

                        headTrackerMode = GetStringContainCheck(eventArgs.Data, 'H'); // head tracker status
                    headTrackerOn = GetStringContainCheck(eventArgs.Data, 'E'); // head tracker on/off status
                    headTrackerOn = !GetStringContainCheck(eventArgs.Data, 'D'); // head tracker on/off status
                }

                }

            };

            bool result = false;
            result = process.Start();

            if (!result)
            {
                isConnected = false;
                Debug.Log("Error in executing the roto chair connection.");
            }
            else
            {
                isConnected = true;
               // Debug.Log("Success executing the roto chair connection.");
            }

            process.BeginOutputReadLine();

            sw = process.StandardInput;
            sw.AutoFlush = true;

        }

        /// <summary>
        /// Close process on appliction exit
        /// </summary>
        private void OnApplicationQuit()
        {
            isConnected = false;

            if (process != null)
                process.Kill();

            if (process != null)
                if (process.HasExited == false)
                    process.Kill();

            processThread.Join();
        }

        #endregion

        #region "DEV COMMANDS"

        #region "Modes"

        /// <summary>
        /// Switch to cockpit mode.
        /// This will disable free mode.
        /// </summary>
        public void EnableCockpitMode()
        {
            WriteCommand("C");
            cockpitMode = true;
            freeMode = false;
        }

        /// <summary>
        // Switch to free mode.
        /// This will disable cockpit mode.
        /// </summary>
        public void EnableFreeMode()
        {
            WriteCommand("F");
            freeMode = true;
            cockpitMode = false;
        }

        /// <summary>
        /// Set to head tracker mode.
        /// </summary>
        public void SetToHeadTrackerMode()
        {
            WriteCommand("H");
        }

        /// <summary>
        /// Switch head tracker on.
        /// </summary>
        public void EnableHeadTracker()
        {
            WriteCommand("E");
        }

        /// <summary>
        /// Switch head tracker off.
        /// </summary>
        public void DisableHeadTracker()
        {
            WriteCommand("D");
        }

        /// <summary>
        /// Sets rumble to auto mode. Rumble with game volume.
        /// </summary>
        public void SetRumbleToAutoMode()
        {
            WriteCommand("A");
            rumbleAuto = true;
            rumblePC = false;
        }

        /// <summary>
        /// Sets rumble to PC mode. Rumble must be selected by the program.
        /// </summary>
        public void SetRumbleToPCMode()
        {
            WriteCommand("P");
            rumblePC = true;
            rumbleAuto = false;
        }

        #endregion

        #region "Movement"
        /// <summary>
        /// Turn the roto chair left to angle at speed: power.
        /// Will only work in Free Mode.
        /// </summary>
        /// <param name="angle"></param>
        /// <param name="power">0 - 100 range</param>
        /// <returns>true if command successful</returns>
        public bool TurnLeftToAngleAtSpeed(int angle, int power)
        {
            SetChairTurnPower(power);
            WriteCommand("L" + GetTrippleDigitString(angle) + GetTrippleDigitString(power));
            currentAngle = angle;
            return true;
        }

        /// <summary>
        /// Turn the roto chair right to angle at speed: power.
        /// Will only work in Free Mode.
        /// </summary>
        /// <param name="angle"></param>
        /// <param name="power">0 - 100 range</param>
        /// <returns>true if command successful</returns>
        public bool TurnRightToAngleAtSpeed(int angle, int power)
        {
            SetChairTurnPower(power);
            WriteCommand("R" + GetTrippleDigitString(angle) + GetTrippleDigitString(power));
            currentAngle = angle;
            return true;
        }

        /// <summary>
        /// Turn to the left at speed power.
        /// Will only work in Free Mode.
        /// </summary>
        /// <param name="angle">degrees to the left, 1 - 359 range</param>
        /// <param name="power">0 - 100 range</param>
        /// <returns>true if command successful</returns>
        public bool TurnLeftAtSpeed(int angle, int power)
        {      
            int newAngle = GetOutputRotation() - angle;

            if (newAngle < 0)
            {
                newAngle += 359;
            }
            TurnLeftToAngleAtSpeed(newAngle, power);

            return true;
            
        }

        /// <summary>
        /// Turn to the right at speed power.
        /// Will only work in Free Mode.
        /// </summary>
        /// <param name="angle">degrees to the right, 1 - 359 range</param>
        /// <param name="power">0 - 100 range</param>
        /// <returns>true if command successful</returns>
        public bool TurnRightAtSpeed(int angle, int power)
        {
            int newAngle = GetOutputRotation() + angle;
            if (newAngle > 359)
            {
                newAngle -= 359;
            }
            TurnRightToAngleAtSpeed(newAngle, power);
            return true;
            
        }

        /// <summary>
        /// Moves the chair to position zero at speed power.
        /// Will only work in Free Mode.
        /// </summary>
        /// <param name="power">0 - 100 range</param>
        /// <returns>true if command successful</returns>
        public bool MoveChairToZero(int power)
        {
            if (power > -1 && power < 101)
            {
                int direction = 360 - GetOutputRotation();
                if (direction < 180) // right
                    TurnRightToAngleAtSpeed(0, power);
                else // left
                    TurnLeftToAngleAtSpeed(0, power);
                return true;
            }
            return false;
        }

        /// <summary>
        /// Move the roto char to the position angle in the shorted direction
        /// </summary>
        /// <param name="angle">degrees to the right, 1 - 359 range</param>
        /// <param name="power">0 - 100 range</param>
        /// <returns>true if command successful</returns>
        public bool MoveShortestRotationToPosition(int angle, int power)
        {
            if (power > -1 && power < 101)
            {
                float diff = Mathf.DeltaAngle(GetOutputRotation(), angle);
                bool left = diff < 0f;
                if (diff > (shortPathBuffer * -1) && diff < shortPathBuffer) // buffer 
                    return false;
                if (left)
                    TurnLeftToAngleAtSpeed(angle, power);
                else
                    TurnRightToAngleAtSpeed(angle, power);
                return true;
            }
            return false;
        }

        /// <summary>
        /// The chair will turn to look at a target. Note use after SyncRotoToVirtualRoto
        /// </summary>
        /// <param name="obj">Target gameobject</param>
        /// <param name="power">0-100 range</param>
        public void ChairLookAtTarget(GameObject targetObj, int power)
        {
            rotoVirtualTarget.transform.LookAt(targetObj.transform); // look at target
            MoveShortestRotationToPosition((int)rotoVirtualTarget.transform.eulerAngles.y, power);
            rotoVirtualTarget.transform.eulerAngles = new Vector3(0f, rotoVirtualTarget.transform.eulerAngles.y, 0f);
        }

        #endregion

        #region "Settings"

        /// <summary>
        /// Set current position to 0 in base.
        /// </summary>
        /// <returns>true if command successful</returns>
        public bool SetCurrentPositionToZero()
        {
            currentAngle = 0;
            WriteCommand("Z");
            return true;
        }

        /// <summary>
        /// Set chair turn power to power.
        /// </summary>
        /// <param name="power">0 - 100 range</param>
        /// <returns>false if invalid</returns>
        public bool SetChairTurnPower(int power)
        {
            if (power < 101 && power > -1) // valid range
            {
                WriteCommand("S" + GetTrippleDigitString(power));
                return true;
            }
            return false;
        }

        /// <summary>
        /// Play rumble at power for time seconds. 
        /// Only valid if the rumble is set to PC mode.
        /// </summary>
        /// <param name="power">0 - 100 range</param>
        /// <param name="time"">0 - 99 range</param>
        /// <returns>true if command successful, false if the power was invalid</returns>
        public bool PlayRumble(int power, int time)
        {
            if (power < 101 && power > -1) // valid range
            {
                if (time < 99 && time > -1)
                {
                    WriteCommand("V" + GetTrippleDigitString(power) + GetTrippleDigitString(time));
                    return true;
                }
            }
            return false;
        }

        #endregion

        #region "Virtual Mimic"

        /// <summary>
        /// Sync the roto physical rotation to the virtual rotation
        /// isSyncing will be set to false after this function is done
        /// </summary>
        /// <param name="power">0 - 100 range</param>
        public IEnumerator SyncRotoToVirtualRoto(int power)
        {
            isSyncing = true;
            SetCurrentPositionToZero();
            rotoVirtualTarget.transform.eulerAngles = Vector3.zero; // sets base to zero

            float tempY = vrHeadSet.transform.eulerAngles.y; // save headset rotation
            float angle = Mathf.DeltaAngle(tempY, rotoVirtualTarget.transform.eulerAngles.y);
            if (angle < 0) // move left
                TurnLeftToAngleAtSpeed(((int)angle) * -1, power);
            else
                TurnRightToAngleAtSpeed(((int)angle), power);

            bool isMoving = true;
            while (isMoving)
            {
                if (currentAngle < (GetOutputRotation() + fidgetBuffer) && currentAngle > (GetOutputRotation() - fidgetBuffer)) // fidgetBuffer - for when player figits
                {
                    isMoving = false;
                }
                yield return new WaitForSeconds(0.3f); // recheck
            }

            tempY = vrHeadSet.transform.eulerAngles.y; // save headset rotation
            angle = (tempY - rotoVirtualTarget.transform.eulerAngles.y + 540) % 360 - 180;
            if (angle < -5f || angle > 5f)
                yield return StartCoroutine(SyncRotoToVirtualRoto(power)); // run again

            SetCurrentPositionToZero();// align roto to virtual zero*/
            isSyncing = false;
        }

        /// <summary>
        /// GameObject model will follow the physical roto chair rotation. Use to have a chair model in the scene
        /// </summary>
        /// <param name="model"></param>
        public void ModelFollowChair(GameObject model)
        {
            var desiredRotQ = Quaternion.Euler(model.transform.localEulerAngles.x, GetOutputRotation(), model.transform.localEulerAngles.z);
            model.transform.localRotation = Quaternion.Lerp(model.transform.localRotation, desiredRotQ, Time.deltaTime * 10f);
        }

        #endregion

        #endregion

        #region MISC

        /// <summary>
        /// Convert int to string wilth tripple digits. Exp: 27 to "027".
        /// </summary>
        /// <param name="val"></param>
        /// <returns>returns tripple didit string</returns>
        private string GetTrippleDigitString(int val)
        {
            if (val < 10) // single digit
            {
                return "00" + val.ToString();
            }
            else if (val < 100) // double digit
            {
                return "0" + val.ToString();
            }
            else // tripple digit
            {
                return val.ToString();
            }
        }

        /// <summary>
        /// Return true if a char is found in the string - used in console feedback states
        /// </summary>
        /// <param name="ss"></param>
        /// <param name="ch"></param>
        /// <returns>returns true if the console has reported ch</returns>
        private bool GetStringContainCheck(string ss, char ch)
        {
            for (int i = 0; i < ss.Length; i++)
            {
                if (ss[i].Equals("0")) // too far if zero found
                {
                    break;
                }
                else if (ss[i].Equals(ch)) // ch found
                {
                    return true;
                }
            }
            return false;
        }

        /// <summary>
        /// Get current rotation from output log
        /// </summary>
        /// <returns></returns>
        public int GetOutputRotation()
        {
            if (lastOutput.Length > 28) // size check - value length will always be the same
            {
                string ss = lastOutput.Substring(25, 3);
                try
                {
                    return int.Parse(ss);
                }
                catch (Exception)
                { }
            }
            return -1;
        }

        /// <summary>
        /// Get virtual targetings rotation
        /// </summary>
        /// <returns></returns>
        /*private int GetVirtualTargeterRotation()
        {
            if(rotoVirtualTarget != null)
            {
                return (int)rotoVirtualTarget.transform.eulerAngles.y;

            }

            return 0;
        }*/

        #endregion

    }
}
