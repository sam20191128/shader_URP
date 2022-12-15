using UnityEngine;

public class SimpleGPUInstancingExample : MonoBehaviour
{
	public Transform Prefab;
	public Material InstancedMaterial;
	void Awake()
	{
#if UNITY_5_6_OR_NEWER
		InstancedMaterial.enableInstancing = true;
#endif
		float range = 4f;

		for ( int i = 0; i < 1000; i++ )
		{
			Transform newInstance = Instantiate( Prefab, new Vector3( Random.Range( -range, range ), range + Random.Range( -range, range ), Random.Range( -range, range ) ), Quaternion.identity ) as Transform;
			MaterialPropertyBlock matpropertyBlock = new MaterialPropertyBlock();
			Color newColor = new Color( Random.Range( 0.0f, 1.0f ), Random.Range( 0.0f, 1.0f ), Random.Range( 0.0f, 1.0f ) );
			matpropertyBlock.SetColor( "_Color", newColor );
			newInstance.GetComponent<MeshRenderer>().SetPropertyBlock( matpropertyBlock );
		}
	}
}
