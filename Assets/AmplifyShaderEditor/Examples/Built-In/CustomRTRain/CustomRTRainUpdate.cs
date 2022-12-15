using UnityEngine;

public class CustomRTRainUpdate : MonoBehaviour
{
	public CustomRenderTexture RainCustomRT;
	public int UpdateCount = 4;

	void Awake()
	{
		RainCustomRT.Initialize();
	}

	void Update()
	{
		RainCustomRT.Update( UpdateCount );
	}
}
