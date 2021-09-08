
using UnityEngine;
using Roto.Control;
using System;


[RequireComponent(typeof(AudioSource))]


public class TESTING : MonoBehaviour
{

    [Header("Speed")]
    [Tooltip("Change the turn speed here")]
    public int speed = 50;

    [Tooltip("Change the turn range here")]
    public int turnRange = 355;

    [Header("Rumble")]
    [Tooltip("Change the rumble power here")]
    public int rumblePower = 40;
    [Tooltip("Change the rubmle time here")]
    public int rumbleTime = 1;

    [Header("Manager")]
    public RotoController rotoCon;

    public int count = 0;
    public int[] profile;
    //public AudioClip clip;
    //public float audioVolume = 0.3F;
    // Use this for initialization

    void Start()
    {
        rotoCon.EnableFreeMode();

        // read in motion profile from "profileName.txt"
        var dataset = Resources.Load<TextAsset>("profileName");
        var lines = dataset.text.Split('\n');    // split .txt into lines
        //public int i = 0;
        profile = new int[lines.Length];
        for (int i = 0; i < lines.Length; i++)
        {
            profile[i] = Int32.Parse(lines[i]); // convert each line to int and add to list
        }

        //rotoCon.TurnRightToAngleAtSpeed(40, 40);

        // AudioSource.PlayClipAtPoint(clip, new V
    }
}