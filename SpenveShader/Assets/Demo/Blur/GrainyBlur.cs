using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class GrainyBlur : MonoBehaviour
{
    public Material mat;
    [Range(0, 0.1f)]
    public float blurRadius = 0.1f;
    [Range(1, 10)]
    public int iteration = 2;

    private int _blurRadiusId;
    private int _iterationId;
    private void OnEnable()
    {
        _blurRadiusId = Shader.PropertyToID("_BlurRadius");
        _iterationId = Shader.PropertyToID("_Iteration");
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (mat == null)
        {
            Graphics.Blit(src, dest);
            return;
        }
        
        mat.SetInt(_iterationId, iteration);
        mat.SetFloat(_blurRadiusId, blurRadius);
        Graphics.Blit(src, dest, mat);
    }
}
