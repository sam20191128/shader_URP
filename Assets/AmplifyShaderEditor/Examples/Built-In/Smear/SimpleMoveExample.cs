using UnityEngine;
using System.Collections;

/// <summary>
/// This is just a simple movement example in which the object is moved
/// to a random location inside a bounding box using smooth lerp
/// </summary>
public class SimpleMoveExample : MonoBehaviour
{
	private Vector3 m_previous;
	private Vector3 m_target;
	private Vector3 m_originalPosition;
	public Vector3 BoundingVolume = new Vector3( 3, 1, 3 );
	public float Speed = 10;

	private void Start()
	{
		m_originalPosition = transform.position;
		m_previous = transform.position;
		m_target = transform.position;
	}

	private void Update()
	{
		transform.position = Vector3.Slerp( m_previous, m_target, Time.deltaTime * Speed );
		m_previous = transform.position;
		if ( Vector3.Distance( m_target, transform.position ) < 0.1f )
		{
			m_target = transform.position + Random.onUnitSphere * Random.Range( 0.7f, 4f );
			m_target.Set( Mathf.Clamp( m_target.x, m_originalPosition.x - BoundingVolume.x, m_originalPosition.x + BoundingVolume.x ), Mathf.Clamp( m_target.y, m_originalPosition.y - BoundingVolume.y, m_originalPosition.y + BoundingVolume.y ), Mathf.Clamp( m_target.z, m_originalPosition.z - BoundingVolume.z, m_originalPosition.z + BoundingVolume.z ) );
		}
	}
}
