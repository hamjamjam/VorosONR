using System.Collections;
using UnityEngine;
using UnityEngine.UI;

namespace Roto.Control
{
    [RequireComponent(typeof(RotoController))]
    public class RotoCalibration : MonoBehaviour
    {
        //[Header("---- Manager ----")]
        private RotoController rotoCon;

        [Header("---- Visuals ----")]
        [SerializeField]
        protected GameObject visualContainer;
        [SerializeField]
        protected Text feedbackText;

        public GameObject chairModel;

        [Header("---- Components ----")]
        [Tooltip("Virtual representation of roto base")]
        public GameObject rotoVirtualTarget;
        [Tooltip("Main camera on the VR headset gameobject")]
        public GameObject vrHeadSet;

        #region "FEEDBACK VARS"
        protected bool headDoneCalibrating = false;
        protected bool chairAtZero = false;

        /// <summary>
        /// Return if the head tracking is complete
        /// </summary>
        public bool HeadDoneCalibrating
        {
            get { return headDoneCalibrating; }
        }

        /// <summary>
        /// Return true if the cahir calibaration is complete
        /// </summary>
        public bool ChairAtZero
        {
            get { return chairAtZero; }
        }

        #endregion

        void Awake()
        {
            rotoCon = GetComponent<RotoController>();
        }

        private void FixedUpdate()
        {
            
            if (rotoCon != null && chairModel != null)
                rotoCon.ModelFollowChair(chairModel);

            if(rotoCon !=null)
            {
                rotoCon.RotoVirtualTarget = rotoVirtualTarget;

                if (vrHeadSet != null)
                    rotoCon.VRHeadSet = vrHeadSet;
                else
                    Debug.Log("VRHeadSet variable not connected in RotoCalibration class");
            }

           /* if(Input.GetKey(KeyCode.Slash))
            {
                if(Input.GetKey(KeyCode.F1))
                {
                    CalibrateChairZero(100);
                }
            }*/
        }

        #region "CALIBRATION"

        /// <summary>
        /// Calibrate the head tracker to work with head tracking mode.
        /// The user must look staight
        /// </summary>
        public void CalibrateHeadTracker()
        {
            headDoneCalibrating = true;
            StartCoroutine(CalHead());
        }

        /// <summary>
        /// Calibrate head tracker funtion.
        /// </summary>
        /// <returns></returns>
        private IEnumerator CalHead()
        {
            string ss = "Calibrating head tracker. \n Please look straight.";
            int count = 3;

            ShowFeedbackText(ss);
            yield return new WaitForSeconds(2f);

            rotoCon.DisableHeadTracker();
            while (count > -1)
            {
                ShowFeedbackText(ss + "\n" + count);

                if (count == 3)
                {
                    rotoCon.EnableHeadTracker();
                    rotoCon.SetToHeadTrackerMode(); // calibration and toggle head tracker
                }

                yield return new WaitForSeconds(1f);
                count--;
            }

            if (!rotoCon.IsHeadTrackerOn)
            {
                ShowFeedbackText("Head tracker calibration failed. \n Check if the head tracker is on and paired.");
                yield return new WaitForSeconds(3f);
            }
            else
            {
                ShowFeedbackText("Head tracker calibration done.");
            }

            yield return new WaitForSeconds(3f);
            ShowFeedbackText("");
            headDoneCalibrating = false;
        }


        /// <summary>
        /// Calibrate the chair zero position to align the chair with the virtual chair/seats
        /// The user must look staight
        /// </summary>
        public void CalibrateChairZero(int power)
        {
            chairAtZero = true;
            StartCoroutine(CalChairZero(power));
        }

        /// <summary>
        /// Calibrate head tracker funtion.
        /// </summary>
        /// <returns></returns>
        private IEnumerator CalChairZero(int power)
        {
            string ss = "Calibrating chair virtual zero position. \n Please look straight.";
            int count = 3;

            ShowFeedbackText(ss);
            yield return new WaitForSeconds(2f);

            while (count > -1)
            {
                ShowFeedbackText(ss + "\n" + count);
                yield return new WaitForSeconds(1f);
                count--;
            }

            ShowFeedbackText(ss);
            StartCoroutine(rotoCon.SyncRotoToVirtualRoto(power));
            while (rotoCon.IsSyncing)
            {
                yield return null;
            }

            ShowFeedbackText("Chair virtual zero calibration done.");
            yield return new WaitForSeconds(3f);
            ShowFeedbackText("");
            chairAtZero = false;
        }

        /// <summary>
        /// Show feedback when using RotoFunctions
        /// </summary>
        /// <param name="ss"></param>
        private void ShowFeedbackText(string ss)
        {
            if (feedbackText != null)
            {
                feedbackText.text = ss;

                if (ss.Equals(""))
                    visualContainer.SetActive(false);
                else
                    visualContainer.SetActive(true);
            }
        }

        #endregion
    }
}
