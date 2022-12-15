using UnityEngine;

namespace TFHC_ForceShield_Shader_Sample
{
    public class ForceShieldDestroyBall : MonoBehaviour
    {
		// Destroy the gameObject after lifetime
        public float lifetime = 5f;

        void Start()
        {
            Destroy(gameObject, lifetime);
        }
    }
}
