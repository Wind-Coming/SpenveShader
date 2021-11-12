using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DualBlur : MonoBehaviour
{
    public Material mat;
    [Range(0, 5)]
    public float blurRadius = 0.1f;
    [Range(0, 10)]
    public int downIteration = 2;
    [Range(0, 10)]
    public int upIteration = 2;
    
    private int _blurRadiusId;

    private void OnEnable()
    {
        _blurRadiusId = Shader.PropertyToID("_BlurRadius");
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (mat == null)
        {
            Graphics.Blit(src, dest);
            return;
        }
        
        mat.SetFloat(_blurRadiusId, blurRadius);

        Vector2Int halfSize = new Vector2Int(Screen.width / 2, Screen.height / 2);

        RenderTexture s1 = RenderTexture.GetTemporary(halfSize.x, halfSize.y, 16);
        Graphics.Blit(src, s1);
        
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
        
        Graphics.Blit(s1, dest, mat);
        RenderTexture.ReleaseTemporary(s1);
    }
}
