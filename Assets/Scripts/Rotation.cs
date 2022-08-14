using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class Rotation : MonoBehaviour
{
    public Vector3 _rotationAxis = new Vector3(0, 1, 0);
    public float _rotationSpeed;
    private Transform _transform;

    void Start()
    {
        _transform = transform;
    }

    void Update()
    {
        _transform.Rotate(_rotationAxis * _rotationSpeed * Time.deltaTime);
    }
}
