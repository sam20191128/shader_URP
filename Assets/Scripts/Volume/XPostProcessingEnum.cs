using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public enum Direction
{
    Horizontal = 0,
    Vertical = 1,
}

public enum DirectionEX
{
    Horizontal = 0,
    Vertical = 1,
    Horizontal_Vertical = 2,
}

public enum IntervalType
{
    Infinite,
    Periodic,
    Random
}

[System.Serializable]
public sealed class DirectionParameter : VolumeParameter<Direction>
{
    public DirectionParameter(Direction value, bool overrideState = false) : base(value, overrideState)
    {
    }
}

[System.Serializable]
public sealed class DirectionEXParameter : VolumeParameter<DirectionEX>
{
    public DirectionEXParameter(DirectionEX value, bool overrideState = false) : base(value, overrideState)
    {
    }
}

[System.Serializable]
public sealed class IntervalTypeParameter : VolumeParameter<IntervalType>
{
    public IntervalTypeParameter(IntervalType value, bool overrideState = false) : base(value, overrideState)
    {
    }
}