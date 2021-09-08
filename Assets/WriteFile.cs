using System.Collections.Generic;
using UnityEngine;
using System.IO;
using Valve.VR;
using UnityEngine.XR; // for eyetracking
using System.Runtime.InteropServices;
using UnityEngine.Assertions;
using ViveSR.anipal.Eye;
using Roto.Control;


public class WriteFile : MonoBehaviour
{
    UnityEngine.XR.InputDevice ViveHMD;

    //Current
    UnityEngine.Vector3 ViveHMDPosition;
    UnityEngine.Quaternion ViveHMDRotation;
    UnityEngine.Vector3 ViveHMDVelocity;
    UnityEngine.Vector3 ViveHMDAngularVelocity;

    // eye tracking
    private static EyeData eyeData = new EyeData();
    private bool eye_callback_registered = false;
    UnityEngine.Vector2 leftEyePos;
    UnityEngine.Vector2 rightEyePos;
    UnityEngine.Vector3 leftEyeGaze;
    UnityEngine.Vector3 rightEyeGaze;

    public SteamVR_Action_Boolean TriggerPinchedLeft;
    public SteamVR_Action_Boolean TriggerPinchedRight;

    public SteamVR_Action_Boolean TrackpadClickedLeft;
    public SteamVR_Action_Boolean TrackpadClickedRight;

    public SteamVR_Input_Sources handTypeLeft;
    public SteamVR_Input_Sources handTypeRight;
    public string path;
    public static GameObject darkSphere;
    public RotoController rotoCon;
    public int lightstate;

    // Testing for eyetracking - Kieran 7/16
    public Eyes eyes;

    //public static DateTime Now { get; }
    //public TurnOnStart startFile;


    void CreateText()
    {
        //Path of the file
        //int val = 0;
        int trialNum = 1;
        //path = Application.dataPath + "/logs/Log" + val + ".txt";
        path = Application.dataPath + "/logs/Subject" + TurnOnStart.subjectNum + "_trial" + trialNum + ".txt";


        darkSphere = GameObject.Find("DarkSphere");
        // if the Path already exists, increment version number until it does not
        while (File.Exists(path))
        {
            //val = val + 1;

            trialNum = trialNum + 1;
            //DateTime localDate = DateTime.Now;
            //path = Application.dataPath + "/logs/Log" + val + ".txt";
            path = Application.dataPath + "/logs/Subject" + TurnOnStart.subjectNum  + "_trial" + trialNum + ".txt";
        }

        File.WriteAllText(path, "Login log \n\n");

        //Content of the file
        string content = "Login date: " + System.DateTime.Now + "\n";
        //Add some to text to it
        File.AppendAllText(path, content);

    }

    void writeTime(string direction)
    {
        //get Path
        //string path = Application.dataPath + "Log.txt";
        //get time
        string content = direction + " Time: " + Time.time + "\n";
        //Add the text
        File.AppendAllText(path, content);
    }

    void writeOrientation()
    {
        //get Path
        //string path = Application.dataPath + "/Log.txt";
        //get time
        string content = "Time: " + Time.time + "\n";
        //prepare orientation string
        UpdateCoordinates();
        string orientation = "Orientation: " + ViveHMDRotation.ToString("F8") + "\n";
        string angularVelocity = "Angular Velocity" + ViveHMDAngularVelocity.ToString("F8") + "\n";


        //get lighting state
        lightstate = 1;
        if (darkSphere.GetComponent<MeshRenderer>().isVisible)
        {
            lightstate = 0;
        }

        string lightstatestr = "Lights: " + lightstate.ToString("F8") + "\n";

        int chairRotation = rotoCon.GetOutputRotation();
        string chairRotationString = "Chair Rotation: " + chairRotation.ToString("F8") + "\n";


        //Add the text
        File.AppendAllText(path, content);
        File.AppendAllText(path, angularVelocity);
        File.AppendAllText(path, chairRotationString);
        if (lightstate != 5)
        {
            File.AppendAllText(path, lightstatestr);
        }

    }
  
    void writeEyePos()
    {

        //get eye positions
        string eyePosString = "Eyes: l) [" + leftEyePos.x.ToString() + ", " + leftEyePos.y.ToString() + "]; r) [" + rightEyePos.x.ToString() + ", " + rightEyePos.y.ToString() + "]; f) " + "\n";
        string eyeGazeString = "Gaze: l) [" + leftEyeGaze.x.ToString() + ", " + leftEyeGaze.y.ToString() + ", " + leftEyeGaze.z.ToString() + "]; r) [" + rightEyeGaze.x.ToString() + ", " + rightEyeGaze.y.ToString() + ", " + rightEyeGaze.z.ToString() + "]; f) " + "\n";


        File.AppendAllText(path, eyePosString);
        File.AppendAllText(path, eyeGazeString);
    }

    void writeProfile()
    {
        //get time
        string content = "Start: " + Time.time + "\nProfile:  " + TurnOnStart.profileText + "\n";

        //Add the text
        File.AppendAllText(path, content);
    }



    //   public SteamVR_Action_Boolean grabPinch; //Grab Pinch is the trigger, select from inspecter
    //    public SteamVR_Input_Sources inputSource = SteamVR_Input_Sources.Any;//which controller
    // public SteamVR_Input_Sources source = SteamVR_Input_Sources.LeftHand;

    // Use this for initialization
    void Start()
    {
        TriggerPinchedLeft.AddOnStateDownListener(TriggerDownLeft, handTypeLeft);
        TriggerPinchedRight.AddOnStateDownListener(TriggerDownRight, handTypeRight);
        TriggerPinchedLeft.AddOnStateUpListener(TriggerUpLeft, handTypeLeft);
        TriggerPinchedRight.AddOnStateUpListener(TriggerUpRight, handTypeRight);

        TrackpadClickedLeft.AddOnStateDownListener(TrackpadDownLeft, handTypeLeft);
        TrackpadClickedLeft.AddOnStateUpListener(TrackpadUpLeft, handTypeLeft);
        TrackpadClickedRight.AddOnStateDownListener(TrackpadDownRight, handTypeRight);
        TrackpadClickedRight.AddOnStateUpListener(TrackpadUpRight, handTypeRight);


        var inputDevices = new List<UnityEngine.XR.InputDevice>();
        UnityEngine.XR.InputDevices.GetDevices(inputDevices);

        foreach (var device in inputDevices)
        {
            Debug.Log(string.Format("Device found with name '{0}' and role '{1}'", device.name, device.characteristics.ToString()));
            if (device.name == "VIVE_Pro MV")
            {
                ViveHMD = device;
                Debug.Log(string.Format("Found the Vive! it's called '{0}'", ViveHMD.name));

                var inputFeatures = new List<UnityEngine.XR.InputFeatureUsage>();
                if (device.TryGetFeatureUsages(inputFeatures))
                {
                    foreach (var feature in inputFeatures)
                    {
                        Debug.Log(string.Format(" feature {0}'s type is {1}, other data {2}", feature.name, feature.type, feature.ToString()));
                    }
                }

            }
            break;
        }

        CreateText();

    }

    public void TriggerDownLeft(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Left Trigger is down");
        writeTime("Trigger Down");
    }
    public void TriggerUpLeft(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Left Trigger is up");
        writeTime("Trigger Up");
    }

    public void TriggerDownRight(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Right Trigger is down");
        writeTime("Trigger Down");
    }
    public void TriggerUpRight(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Right Trigger is up");
        writeTime("Trigger Up");
    }


    public void TrackpadDownLeft(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Left Trackpad is down");
        writeTime("Left Trackpad Down");
    }

    public void TrackpadUpLeft(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Left Trackpad is up");
        writeTime("Left Trackpad Up");
    }

    public void TrackpadDownRight(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Right Trackpad is down");
        writeTime("Right Trackpad Down");
    }

    public void TrackpadUpRight(SteamVR_Action_Boolean fromAction, SteamVR_Input_Sources fromSource)
    {
        Debug.Log("Right Trackpad is up");
        writeTime("Right Trackpad Up");
    }



    // Update is called once per frame


    void Update()
    {
        // writes current orientation (and others)
        writeOrientation();

        // writes profile start time
        if (Input.GetKey(KeyCode.S))
        {
            writeProfile();
        }

        // Eye tracking framework setup?
        if (SRanipal_Eye_Framework.Status != SRanipal_Eye_Framework.FrameworkStatus.WORKING &&
                        SRanipal_Eye_Framework.Status != SRanipal_Eye_Framework.FrameworkStatus.NOT_SUPPORT) return;

        if (SRanipal_Eye_Framework.Instance.EnableEyeDataCallback == true && eye_callback_registered == false)
        {
            //SRanipal_Eye.WrapperRegisterEyeDataCallback(Marshal.GetFunctionPointerForDelegate((SRanipal_Eye.CallbackBasic)EyeCallback));
            eye_callback_registered = true;
        } else if (SRanipal_Eye_Framework.Instance.EnableEyeDataCallback == false && eye_callback_registered == true) {
            //SRanipal_Eye.WrapperUnRegisterEyeDataCallback(Marshal.GetFunctionPointerForDelegate((SRanipal_Eye.CallbackBasic)EyeCallback));
            eye_callback_registered = false;
        }
        else if (SRanipal_Eye_Framework.Instance.EnableEyeDataCallback == false)
            SRanipal_Eye_API.GetEyeData(ref eyeData);

        //
        leftEyePos = new Vector2(0.0f, 0.0f);
        rightEyePos = new Vector2(0.0f, 0.0f);
        leftEyeGaze = new Vector3(0.0f, 0.0f, 0.0f);
        rightEyeGaze = new Vector3(0.0f, 0.0f, 0.0f);
        if (SRanipal_Eye_Framework.Status == SRanipal_Eye_Framework.FrameworkStatus.WORKING)
        {
            leftEyePos = eyeData.verbose_data.left.pupil_position_in_sensor_area;
            rightEyePos = eyeData.verbose_data.right.pupil_position_in_sensor_area;
            leftEyeGaze = eyeData.verbose_data.left.gaze_direction_normalized;
            rightEyeGaze = eyeData.verbose_data.right.gaze_direction_normalized;
        }

        // writes eye tracking data
        // writeEyePos();
    }

    void UpdateCoordinates()
    {
        //ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.devicePosition, out ViveHMDPosition);
        //ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.deviceRotation, out ViveHMDRotation);
        //ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.deviceVelocity, out ViveHMDVelocity);
        //ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.deviceAngularVelocity, out ViveHMDAngularVelocity);
        ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.centerEyePosition, out ViveHMDPosition);
        ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.centerEyeRotation, out ViveHMDRotation);
        ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.centerEyeVelocity, out ViveHMDVelocity);
        ViveHMD.TryGetFeatureValue(UnityEngine.XR.CommonUsages.centerEyeAngularVelocity, out ViveHMDAngularVelocity);

    }
}
