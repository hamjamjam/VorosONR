
using UnityEngine;
using Roto.Control;
using System;
using UnityEngine.XR;
//using System.Collections;

//[RequireComponent(typeof(AudioSource))]

public class TurnOnStart : MonoBehaviour
{

    // CHANGE THE FOLLOWING 
    public static string subjectNum = "test";
    public static string profileText = "Practice_1";

    /* New Motion Profile Testing Order
     * 
Practice #1:  |   Practice_1
Practice #2:  |   Practice_2
Practice #3:  |   Practice_3
Practice #4:  |   Practice_4
=========================================
Trial # 5:    |   35_to_0--Lights_io
Trial # 6:    |   neg_20_to_50--Lights_oo
Trial # 7:    |   neg_20_to_50--Lights_oi
Trial # 8:    |   ramp51-to-43--Lights_oi
Trial # 9:    |   multistep2--Lights_ii
Trial #10:    |   neg_20_to_50--Lights_io
Trial #11:    |   neg_ramp29-to-37--Lights_oi
Trial #12:    |   ramp51-to-43--Lights_oo
Trial #13:    |   multistep2--Lights_oo
Trial #14:    |   neg_multistep1--Lights_ii
Trial #15:    |   multistep2--Lights_io
Trial #16:    |   neg_multistep1--Lights_oi
Trial #17:    |   neg_multistep1--Lights_io
Trial #18:    |   neg_20_to_50--Lights_ii
Trial #19:    |   35_to_0--Lights_ii
Trial #20:    |   ramp51-to-43--Lights_ii
Trial #21:    |   neg_ramp29-to-37--Lights_ii
Trial #22:    |   35_to_0--Lights_oi
Trial #23:    |   neg_ramp29-to-37--Lights_io
Trial #24:    |   neg_ramp29-to-37--Lights_oo
Trial #25:    |   35_to_0--Lights_oo
Trial #26:    |   ramp51-to-43--Lights_io
Trial #27:    |   multistep2--Lights_oi
Trial #28:    |   neg_multistep1--Lights_oo
     * 
    */

    [Header("Speed")]
    [Tooltip("Change the turn speed here")]
    public int speed = 50;
    
    [Tooltip("Change the turn range here")]
    public int turnRange = 355;

    [Header("Rumble")]
    [Tooltip("Change the rumble power here")]
    public int rumblePower = 90;
    [Tooltip("Change the rumble time here")]
    public int rumbleTime = 10;

    [Header("Manager")]
    public RotoController rotoCon;

    public int count = 0;
    public int[] found;
    public bool quitProfile = false;
    public int[] profile;
    public int[] lights;
    public int[] noise;
  
    
    public static GameObject darkSphere;
    public static GameObject wiffleBall;
    public static GameObject Crosshairs_scene;
    public static GameObject Crosshairs_camera;
    public static AudioSource backNoise;

    //public AudioClip clip;
    //public float audioVolume = 0.3F;
    // Use this for initialization

    void Start()
    {
        rotoCon.EnableFreeMode();
        darkSphere = GameObject.Find("DarkSphere");
        wiffleBall = GameObject.Find("WiffleBall");
        Crosshairs_scene = GameObject.Find("Crosshairs_scene");
        Crosshairs_camera = GameObject.Find("Crosshairs_camera");
        backNoise = GetComponent<AudioSource>();


        // read in motion profile and light profile from "profileName.txt"
        // don't include the .txt here!
        var dataset = Resources.Load<TextAsset>(profileText);
        var lines = dataset.text.Split('\n');    // split .txt into lines
        //public int i = 0;
        profile = new int[lines.Length];
        lights = new int[lines.Length];
        noise = new int[lines.Length];
        found = new int[2];



        for (int i = 0; i < lines.Length-1; i++) // 
        {
            found[0] = lines[i].IndexOf(",");
            found[1] = lines[i].LastIndexOf(",");
            profile[i] = Int32.Parse(lines[i].Substring(0, found[0])); // convert each line to int and add to list
            lights[i] = Int32.Parse(lines[i].Substring(found[0] + 1, 1));
            noise[i] = Int32.Parse(lines[i].Substring(found[1] + 1, 1));
        }

        Debug.Log(found[1]);
        
        //rotoCon.TurnRightToAngleAtSpeed(40, 40);

        // AudioSource.PlayClipAtPoint(clip, new Vector3(0, 0, 0), audioVolume);
    }

    // Update is called once per frame
    void FixedUpdate()
    {

        if (Input.GetKey(KeyCode.Escape))
        {
            quitProfile = true;
        }


        if (Input.GetKey(KeyCode.C))
        {
            UnityEngine.Vector3 ViveHMDPosition;
            Crosshairs_scene.transform.position = Crosshairs_camera.transform.position;
            Crosshairs_scene.transform.rotation = Crosshairs_camera.transform.rotation;

        }



        // runs profile while profile is defined
        if (Input.GetKey(KeyCode.S))
        {
            quitProfile = false;
            count = 1;
            Crosshairs_scene.SetActive(false);
            Crosshairs_camera.SetActive(false);
        }
        else if (count > 0 && count < profile.Length && !quitProfile)
        {
            runProfile();
            count += 1; // counter updates at 90Hz (count = 90 at 1 second)
        }
        else if (count >= profile.Length)
        {
            Debug.Log("Trial is complete!");
            doneSpinning = true;

        }

        // chair control hotkeys
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            TurnLeft();
        }
        else if (Input.GetKey(KeyCode.RightArrow))
        {
            TurnRight();
        }
        else if (Input.GetKey(KeyCode.UpArrow) && !spinning)
        {
            initiateSpin();
        }
        else if (Input.GetKey(KeyCode.DownArrow) && !spinning)
        {
            initiateSpinAccel();
        }
        else if (!doneSpinning)
        {
            continueSpin();
        }
        else if (!doneSpinningAccel)
        {
            continueSpinAccel();
        }


        // play rumble with the space bar --> DOES NOT WORK
        if (Input.GetKey(KeyCode.Space))
        {
            PlayRumble2();
        }

        // toggle lights with the L key
        if (Input.GetKeyDown(KeyCode.L))
        {
            lightsOn();
        }
        else if (Input.GetKeyUp(KeyCode.L))
        {
            lightsOff();
        }

        // toggle noise with the n key
        if (Input.GetKeyDown(KeyCode.N))
        {
            playNoise();
        }
        else if (Input.GetKeyUp(KeyCode.N))
        {
            pauseNoise();
        }

        
        float degreesPerSecond = 0.5f;
        if (Input.GetKey(KeyCode.B))
        {
            wiffleBall.transform.Rotate(new Vector3(0.0f, 0.0f, degreesPerSecond), Space.Self);
        }
        else if (Input.GetKey(KeyCode.V))
        {
            wiffleBall.transform.Rotate(new Vector3(0.0f, 0.0f, -degreesPerSecond), Space.Self);
        }
       
                

    }

    public bool spinning = false;
    public float timer = 0;
    public bool doneSpinning = true;
    public bool playingNoise = false;
    public bool doneSpinningAccel = true;
    public int speedTest = 50;


    private void initiateSpin()
    {
        spinning = true;
        timer = 0;
        doneSpinning = false;
    }

    private void initiateSpinAccel()
    {
        spinning = true;
        timer = 0;
        doneSpinningAccel = false;
    }

    private void continueSpinAccel()
    {
        if (timer < 60)
        {
            doneSpinningAccel = false;
            int spinPower = 20 + (int)(timer * 1);
            spinPower = Mathf.Min(spinPower, 100);
            rotoCon.TurnLeftAtSpeed(90, spinPower);
            timer += Time.deltaTime;
            Debug.Log(spinPower);
            Debug.Log(timer);
        }
        else if (timer > 10)
        {
            doneSpinningAccel = true;
            spinning = false;
            Debug.Log("Done");
        }
    }

    private void continueSpin()
    {
        if (timer < 60)
        {
            doneSpinning = false;
            timer += Time.deltaTime;
            rotoCon.TurnLeftAtSpeed(90, speed);
            Debug.Log(timer);
        }
        else if (timer > 10) // is this supposed to be >60?
        {
            doneSpinning = true;
            spinning = false;
        }
    }


    private void TurnLeft()
    {
        Debug.Log("Turn Left " + turnRange + " at " + speed);
        rotoCon.TurnLeftAtSpeed(turnRange, speed);
    }

    private void TurnRight()
    {
        Debug.Log("Turn Right " + turnRange + " at " + speed);
        rotoCon.TurnRightAtSpeed(turnRange, speed);
    }

    private void runProfile()
    {
        // set speed to (count) step in the profile
        speed = profile[count];
        //rotoCon.SetRumbleToAutoMode();

        // turn chair right at speed if negative and left if positive
        if (speed > 0)
        {
            Debug.Log("Turn Left " + turnRange + " at " + speed);
            rotoCon.TurnLeftAtSpeed(turnRange, speed);
        }
        else 
        {
            Debug.Log("Turn Right " + turnRange + " at " + Math.Abs(speed));
            rotoCon.TurnRightAtSpeed(turnRange, Math.Abs(speed));
        }

        if (lights[count] == 1)
        {
            lightsOn();
        }
        else if (lights[count] == 0)
        {
            lightsOff();
        }

        if (noise[count] == 1)
        {
            // plays rumble while noise is playing
            //PlayRumble();
            //rotoCon.SetRumbleToAutoMode();
            // plays noise while noise is commanded and noise isn't already playing
            if (!playingNoise)
            { 
                playNoise();
                playingNoise = true;
            }
        }
        else if (noise[count] == 0 && playingNoise)
        {
            pauseNoise();
            playingNoise = false;
        }
    }

    //  functions to toggle "lights"
    private void lightsOn()
    {
        darkSphere.GetComponent<Renderer>().enabled = false;
    }
    private void lightsOff()
    {
        darkSphere.GetComponent<Renderer>().enabled = true;
    }


    //  functions to toggle noise
    private void playNoise()
    {
        backNoise.Play();

    }
    private void pauseNoise()
    {
        backNoise.Pause();
    }

    /// <summary>
    /// Play rumble at power and time
    /// </summary>
    /// 

    private void PlayRumble2()
    {
        rumblePower = 100;
        rumbleTime = 10;
        Debug.Log("Play rumble " + rumblePower + " at " + rumbleTime);
        rotoCon.SetRumbleToPCMode(); // important to have rumble in PC mode before calling Play Rumble
        rotoCon.PlayRumble(rumblePower, rumbleTime);
    }

    private void spinBall()
    {
        wiffleBall.transform.Rotate(0.0f, 0.0f, 1.0f, Space.World);
    }

    public string getProfileText()
    {
        return profileText;
    }
}
