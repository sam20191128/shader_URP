using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[VolumeComponentMenu("Custom Post-processing/Test Test Test!")]
public class TestVolumeComponent : CustomVolumeComponent
{
    public ClampedFloatParameter foo = new ClampedFloatParameter(.5f, 0, 1f);

    public override bool IsActive()
    {
        return false;
    }

    public override void Render(CommandBuffer cmd, ref RenderingData renderingData, RenderTargetIdentifier source, RenderTargetIdentifier destination)
    {
    }

    public override void Setup()
    {
    }
}