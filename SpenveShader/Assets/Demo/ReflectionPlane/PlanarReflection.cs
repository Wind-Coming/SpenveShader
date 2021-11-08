using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PlanarReflection : MonoBehaviour
{
    public Camera reflectionCamera = null;
    private RenderTexture reflectionRT = null;
    private bool isReflectionCameraRendering = false;
    private Material reflectionMaterial = null;
 
    private void OnWillRenderObject()
    {
        if (isReflectionCameraRendering)
            return;
 
        isReflectionCameraRendering = true;
       
        if (reflectionCamera == null)
        {
            var go = new GameObject("Reflection Camera");
            reflectionCamera = go.AddComponent<Camera>();
            reflectionCamera.CopyFrom(Camera.current);
            reflectionCamera.hideFlags = HideFlags.HideAndDontSave;
        }
        if (reflectionRT == null)
        {
            reflectionRT = RenderTexture.GetTemporary(128, 128, 24);
        }
        //需要实时同步相机的参数，比如编辑器下滚动滚轮，Editor相机的远近裁剪面就会变化
        UpdateCamearaParams(Camera.current, reflectionCamera);
        reflectionCamera.targetTexture = reflectionRT;
        reflectionCamera.enabled = false;
 
        var reflectM = CaculateReflectMatrix();
        reflectionCamera.worldToCameraMatrix = Camera.current.worldToCameraMatrix * reflectM;
 
        var normal = transform.up;
        var d = -Vector3.Dot(normal, transform.position);
        var plane = new Vector4(normal.x, normal.y, normal.z, d);
        //用逆转置矩阵将平面从世界空间变换到反射相机空间
        var clipMatrix = CalculateObliqueMatrix(plane, reflectionCamera);
        reflectionCamera.projectionMatrix = clipMatrix;
        
        GL.invertCulling = true;
        reflectionCamera.Render();
        GL.invertCulling = false;
 
        if (reflectionMaterial == null)
        {
            var renderer = GetComponent<Renderer>();
            reflectionMaterial = renderer.sharedMaterial;
        }
        reflectionMaterial.SetTexture("_ReflectionTex", reflectionRT);
 
        isReflectionCameraRendering = false;
    }
 
    Matrix4x4 CaculateReflectMatrix()
    {
        var normal = transform.up;
        var d = -Vector3.Dot(normal, transform.position);
        var reflectM = new Matrix4x4();
        reflectM.m00 = 1 - 2 * normal.x * normal.x;
        reflectM.m01 = -2 * normal.x * normal.y;
        reflectM.m02 = -2 * normal.x * normal.z;
        reflectM.m03 = -2 * d * normal.x;
 
        reflectM.m10 = -2 * normal.x * normal.y;
        reflectM.m11 = 1 - 2 * normal.y * normal.y;
        reflectM.m12 = -2 * normal.y * normal.z;
        reflectM.m13 = -2 * d * normal.y;
 
        reflectM.m20 = -2 * normal.x * normal.z;
        reflectM.m21 = -2 * normal.y * normal.z;
        reflectM.m22 = 1 - 2 * normal.z * normal.z;
        reflectM.m23 = -2 * d * normal.z;
 
        reflectM.m30 = 0;
        reflectM.m31 = 0;
        reflectM.m32 = 0;
        reflectM.m33 = 1;
        return reflectM;
    }
 
    private void OnDisable()
    {
        RenderTexture.ReleaseTemporary(reflectionRT);
        reflectionRT = null;
    }
 
    private void UpdateCamearaParams(Camera srcCamera, Camera destCamera)
    {
        if (destCamera == null || srcCamera == null)
            return;
 
        destCamera.clearFlags = srcCamera.clearFlags;
        destCamera.backgroundColor = srcCamera.backgroundColor;
        destCamera.farClipPlane = srcCamera.farClipPlane;
        destCamera.nearClipPlane = srcCamera.nearClipPlane;
        destCamera.orthographic = srcCamera.orthographic;
        destCamera.fieldOfView = srcCamera.fieldOfView;
        destCamera.aspect = srcCamera.aspect;
        destCamera.orthographicSize = srcCamera.orthographicSize;
    }
 
    private Matrix4x4 CalculateObliqueMatrix(Vector4 plane, Camera camera)
    {
        var viewSpacePlane = camera.worldToCameraMatrix.inverse.transpose * plane;
        var projectionMatrix = camera.projectionMatrix;
 
        var clipSpaceFarPanelBoundPoint = new Vector4(Mathf.Sign(viewSpacePlane.x), Mathf.Sign(viewSpacePlane.y), 1, 1);
        var viewSpaceFarPanelBoundPoint = camera.projectionMatrix.inverse * clipSpaceFarPanelBoundPoint;
        
        var m4 = new Vector4(projectionMatrix.m30, projectionMatrix.m31, projectionMatrix.m32, projectionMatrix.m33);
        //u = 2 * (M4·E)/(E·P)，而M4·E == 1，化简得
        //var u = 2.0f * Vector4.Dot(m4, viewSpaceFarPanelBoundPoint) / Vector4.Dot(viewSpaceFarPanelBoundPoint, viewSpacePlane);
        var u = 2.0f / Vector4.Dot(viewSpaceFarPanelBoundPoint, viewSpacePlane);
        var newViewSpaceNearPlane = u * viewSpacePlane;
 
        //M3' = P - M4
        var m3 = newViewSpaceNearPlane - m4;
 
        projectionMatrix.m20 = m3.x;
        projectionMatrix.m21 = m3.y;
        projectionMatrix.m22 = m3.z;
        projectionMatrix.m23 = m3.w;
 
        return projectionMatrix;
    }
}
