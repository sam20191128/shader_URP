using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ImageEffectAllowedInSceneView]
[ExecuteInEditMode]
public class Pixelize : MonoBehaviour
{
	#region Private Members
	private Shader _screenAndMaskShader;
	private Material _screenAndMaskMaterial;
	private RenderTexture _temporaryRenderTexture;
	private Shader _combineLayersShader;
	private Material _combineLayersMaterial;
	#endregion

	#region Properties
	private Shader ScreenAndMaskShader
	{
		get
		{
			if(_screenAndMaskShader == null)
			{
				_screenAndMaskShader = Shader.Find("Hidden/PostProcess/Pixelize/ScreenAndMask");
			}

			return _screenAndMaskShader;
		}
	}
 
	private Material ScreenAndMaskMaterial
	{
		get
		{
			if(_screenAndMaskMaterial == null)
			{
				_screenAndMaskMaterial = new Material(ScreenAndMaskShader);
			}

			return _screenAndMaskMaterial;
		}
	}

	private RenderTexture TemporaryRenderTarget
	{
		get
		{
			if(_temporaryRenderTexture == null)
			{
				CreateTemporaryRenderTarget();
			}

			return _temporaryRenderTexture;
		}
	}

	private Shader CombineLayersShader
	{
		get
		{
			if(_combineLayersShader == null)
			{
				_combineLayersShader = Shader.Find("Hidden/PostProcess/Pixelize/CombineLayers");
			}

			return _combineLayersShader;
		}
	}

	private Material CombineLayersMaterial
	{
		get
		{
			if(_combineLayersMaterial == null)
			{
				_combineLayersMaterial = new Material(CombineLayersShader);
			}

			return _combineLayersMaterial;
		}
	}
	#endregion

	#region Functions
	void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		CheckTemporaryRenderTarget();
		
		Graphics.Blit(src, TemporaryRenderTarget, ScreenAndMaskMaterial);

		Graphics.Blit(TemporaryRenderTarget, dest, CombineLayersMaterial);
	}

	private void CreateTemporaryRenderTarget()
	{
		_temporaryRenderTexture = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.Default, RenderTextureReadWrite.Linear); // better bit precision on Alpha would be preferable but 8 is enough for the current pixelization effect which is already banded
		_temporaryRenderTexture.useMipMap = true;
		_temporaryRenderTexture.autoGenerateMips = true;
		_temporaryRenderTexture.wrapMode = TextureWrapMode.Clamp;
		_temporaryRenderTexture.filterMode = FilterMode.Point;
		_temporaryRenderTexture.Create();
	}

	private void CheckTemporaryRenderTarget()
	{
		if(TemporaryRenderTarget.width != Screen.width || TemporaryRenderTarget.width != Screen.height)
		{
			ReleaseTemporaryRenderTarget();
		}
	}

	private void ReleaseTemporaryRenderTarget()
	{
		_temporaryRenderTexture.Release();
		_temporaryRenderTexture = null;
	}
	#endregion
}
