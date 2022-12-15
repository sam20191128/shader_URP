using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class VolumetricSphere : MonoBehaviour
{
	#region Public Members
	[Header("Parameters")]
	[Tooltip("The radius of the sphere")]
	[Range(0.0f,50.0f)]public float radius = 3.0f;
	[Tooltip("The density of the sphere")]
	[Range(0.0f,10.0f)]public float density = 1.0f;
	[Tooltip("The curve of the fade-out")]
	[Range(0.2f,5.0f)]public float exponent = 1.0f/3.0f;
	[Tooltip("The maximum pixelization size")]
	[Range(1,10)]public int maxPixelizationLevel = 5;
	[Tooltip("Enabled the interpolation between the layers of different pixels size")]
	public bool enableLayersInterpolation = true;
	[Header("Debug")]
	[Tooltip("Outputs the sphere mask")]
	public bool debugSphere = false;
	#endregion

	#region Functions
    void Update()
    {
		Shader.SetGlobalVector("_SpherePosition", transform.position);
		Shader.SetGlobalFloat("_SphereRadius", radius);
		Shader.SetGlobalFloat("_MaskDensity", density);
		Shader.SetGlobalFloat("_MaskExponent", exponent);
		Shader.SetGlobalInt("_MaxPixelizationLevel", maxPixelizationLevel);

		if (enableLayersInterpolation)
		{
			Shader.EnableKeyword("_INTERPOLATE_LAYERS_ON");
		}
		else
		{
			Shader.DisableKeyword("_INTERPOLATE_LAYERS_ON");
		}
	    
	    if (debugSphere)
	    {
		    Shader.EnableKeyword("_DEBUG_MASK_ON");
	    }
	    else
	    {
		    Shader.DisableKeyword("_DEBUG_MASK_ON");
	    }
    }

	//void OnDrawGizmos()
	//{
	//	Color color = Color.green;
	//	color.a = 0.35f;
    //    Gizmos.color = color;		
    //    Gizmos.DrawWireSphere(transform.position, radius);
	//}
	
	void OnDrawGizmosSelected()
	{
		Gizmos.color = Color.green;		
		Gizmos.DrawWireSphere(transform.position, radius);
	}
	#endregion
}
