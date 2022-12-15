using UnityEngine;

[ExecuteInEditMode]
public class PostProcessExample : MonoBehaviour
{
	public Material PostProcessMat;
	private void Awake()
	{
		if( PostProcessMat == null )
		{
			enabled = false;
		}
		else
		{
			// This is on purpose ... it prevents the know bug
			// https://issuetracker.unity3d.com/issues/calling-graphics-dot-blit-destination-null-crashes-the-editor
			// from happening
			PostProcessMat.mainTexture = PostProcessMat.mainTexture;
		}

	}

	void OnRenderImage( RenderTexture src, RenderTexture dest )
	{
		Graphics.Blit( src, dest, PostProcessMat );
	}
}
