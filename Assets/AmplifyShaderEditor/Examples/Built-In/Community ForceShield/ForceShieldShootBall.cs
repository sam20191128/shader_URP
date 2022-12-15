using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace TFHC_ForceShield_Shader_Sample
{
    public class ForceShieldShootBall : MonoBehaviour
    {

		// Shooting balls XD 

        public Rigidbody bullet;
        public Transform origshoot;
        public float speed = 1000.0f;
        private float distance = 10.0f;

        void Update()
        {
            if (Input.GetButtonDown("Fire1"))
            {
                Vector3 targetpoint = new Vector3(Input.mousePosition.x, Input.mousePosition.y, distance);
                targetpoint = Camera.main.ScreenToWorldPoint(targetpoint);
                Rigidbody bulletInstance = Instantiate(bullet, transform.position, Quaternion.identity) as Rigidbody;
                bulletInstance.transform.LookAt(targetpoint);
                bulletInstance.AddForce(bulletInstance.transform.forward * speed);
            }

        }
    }

}
