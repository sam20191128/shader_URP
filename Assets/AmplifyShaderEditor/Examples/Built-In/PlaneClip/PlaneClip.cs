// Amplify Shader Editor - Visual Shader Editing Tool
// Copyright (c) Amplify Creations, Lda <info@amplify.pt>
using UnityEngine;

[ExecuteInEditMode]
public class PlaneClip : MonoBehaviour 
{
	public Material PlaneClipMat; 
	private Transform m_transform;
	private int m_planePropertyId;
	void Start () 
	{
		m_planePropertyId = Shader.PropertyToID( "_PlaneClipNormals" );
		m_transform = transform;
	}
	
	void Update () 
	{
		Plane plane = new Plane( m_transform.up, m_transform.position );
		Vector4 planeNormals = new Vector4( plane.normal.x, plane.normal.y, plane.normal.z, plane.distance );
		Shader.SetGlobalVector( m_planePropertyId, planeNormals );
	}
}
