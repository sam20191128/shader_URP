// Amplify Shader Editor - Visual Shader Editing Tool
// Copyright (c) Amplify Creations, Lda <info@amplify.pt>

using UnityEngine;
using UnityEngine.Sprites;

[ExecuteInEditMode]
public class SpriteMaskController : MonoBehaviour
{
	private SpriteRenderer m_spriteRenderer;
	private Vector4 m_uvs;

	void OnEnable ()
	{
		m_spriteRenderer = GetComponent<SpriteRenderer>();
		m_uvs = DataUtility.GetInnerUV( m_spriteRenderer.sprite );
		m_spriteRenderer.sharedMaterial.SetVector( "_CustomUVS", m_uvs );
	}
}
