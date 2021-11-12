using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Bloom : MonoBehaviour
{
    public Material mat;
    [Range(0, 5)]
    public float blurRadius = 0.1f;
    [Range(0, 1)]
    public float luminanceThreshold = 0.5f;
    [Range(0, 5)]
    public float intensity = 1f;
    [Range(0, 10)]
    public int downIteration = 2;
    [Range(0, 10)]
    public int upIteration = 2;
    
    private int _blurRadiusId;
    private int _luminanceThresholdId;
    private int _intensityId;
    private int _BlurTexId;

    private void OnEnable()
    {
        _blurRadiusId = Shader.PropertyToID("_BlurRadius");
        _luminanceThresholdId = Shader.PropertyToID("_LuminanceThreshold");
        _BlurTexId = Shader.PropertyToID("_BlurTex");
        _intensityId = Shader.PropertyToID("_Intensity");
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (mat == null)
        {
            Graphics.Blit(src, dest);
            return;
        }
        
        mat.SetFloat(_blurRadiusId, blurRadius);
        mat.SetFloat(_luminanceThresholdId, luminanceThreshold);
        mat.SetFloat(_intensityId, intensity);

        //如果效果不好可以改成除2
        Vector2Int halfSize = new Vector2Int(Screen.width / 2, Screen.height / 2);

        RenderTexture s1 = RenderTexture.GetTemporary(halfSize.x, halfSize.y, 16);
        Graphics.Blit(src, s1, mat, 2);
        
        for (int i = 0; i < downIteration; i++)
        {
            halfSize /= 2;
            RenderTexture s2 = RenderTexture.GetTemporary(halfSize.x, halfSize.y, 16);
            Graphics.Blit(s1, s2, mat, 0);
            RenderTexture.ReleaseTemporary(s1);
            s1 = s2;
        }
        
        int up = Mathf.Min(upIteration, downIteration);
        for (int i = 0; i < up; i++)
        {
            halfSize *= 2;
            RenderTexture s2 = RenderTexture.GetTemporary(halfSize.x, halfSize.y, 16);
            Graphics.Blit(s1, s2, mat, 1);
            RenderTexture.ReleaseTemporary(s1);
            s1 = s2;
        }
        
        mat.SetTexture(_BlurTexId, s1);
        Graphics.Blit(src, dest, mat, 3);
        RenderTexture.ReleaseTemporary(s1);
    }
}
