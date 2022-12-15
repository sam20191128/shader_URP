using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace TFHC_ForceShield_Shader_Sample
{

    public class ForceShieldImpactDetection : MonoBehaviour
    {


        private float hitTime;
        private Material mat;

        void Start()
        {

			// Store material reference
            mat = GetComponent<Renderer>().material;

        }

        void Update()
        {

			// Animate the _hitTime shader property for impact effect
            if (hitTime > 0)
            {
                hitTime -= Time.deltaTime * 1000;
                if (hitTime < 0)
                {
                    hitTime = 0;
                }
                mat.SetFloat("_HitTime", hitTime);
            }

        }

        void OnCollisionEnter(Collision collision)
        {
			// On colission set shader vector property _HitPosition with the impact point and
			// set _hittime shader property to start the impact effect
            foreach (ContactPoint contact in collision.contacts)
            {
                mat.SetVector("_HitPosition", transform.InverseTransformPoint(contact.point));
                hitTime = 500;
				mat.SetFloat("_HitTime", hitTime);
            }
        }
    }

}
