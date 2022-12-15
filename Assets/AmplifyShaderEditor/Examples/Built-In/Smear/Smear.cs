using UnityEngine;
using System.Collections;
using System.Collections.Generic;

// You can execute this in the editor as long as you don't instantiate the material
//[ExecuteInEditMode]
public class Smear : MonoBehaviour
{
	Queue<Vector3> m_recentPositions = new Queue<Vector3>();

	public int FramesBufferSize = 0;

	public Renderer Renderer = null;

	private Material m_instancedMaterial;
	private Material InstancedMaterial
	{
		get { return m_instancedMaterial; }
		set { m_instancedMaterial = value; }
	}

	private void Start()
	{
		// Instantiate the material so every object has a unique smear effect
		InstancedMaterial = Renderer.material;

		// Use this instead if you want to affect all objects at the same time or if you want to run in the editor
		//InstancedMaterial = Renderer.sharedMaterial;
	}

	private void LateUpdate()
	{
		// Feed the previous position in the queue to the shader
		if ( m_recentPositions.Count > FramesBufferSize )
			InstancedMaterial.SetVector( "_PrevPosition", m_recentPositions.Dequeue() );

		// Feed the current anchor position to the shader
		InstancedMaterial.SetVector( "_Position", transform.position );
		m_recentPositions.Enqueue( transform.position );
	}
}
