using System;
using UnityEditor;
using UnityEngine;

public class FX_Combine_Inspector : ShaderGUI
{
    //材质属性
    enum BlendMode { Alpha, Add }

    MaterialProperty _Cull = null;

    MaterialProperty _UseCustomdata = null;

    MaterialProperty _Color = null;
    MaterialProperty _MainTexture = null;
    MaterialProperty _UVAnimation = null;
    MaterialProperty _MainUV = null;
    MaterialProperty _Loop = null;

    MaterialProperty _UseDissolve = null;
    MaterialProperty _EdgeColor = null;
    MaterialProperty _DissolveMap = null;
    MaterialProperty _DissolveUV = null;
    MaterialProperty _Clip = null;
    MaterialProperty _EdgeRange = null;
    MaterialProperty _EnableTwist = null;

    MaterialProperty _UseMask = null;
    MaterialProperty _MaskMap = null;
    MaterialProperty _MaskUV = null;

    MaterialProperty _UseTwist = null;
    MaterialProperty _TwistMap = null;
    MaterialProperty _TwistUV = null;
    MaterialProperty _TwistStrength = null;

    MaterialProperty _UseRim = null;
    MaterialProperty _ApplyAlpha = null;
    MaterialProperty _FresnelColor = null;
    MaterialProperty _FresnelRange = null;
    MaterialProperty _ZWrite = null;
    MaterialProperty _ZTest = null;

    MaterialEditor _Editor = null;
    Material TargetMat = null;

    //其他属性
    bool _MainTextureLog = false;
    bool _DissolveLog = false;
    bool _TwistLog = false;
    bool _RimLog = false;
    bool _CustomDataLog = false;
    bool _MaskLog = false;

    BlendMode _Blend = new BlendMode();
    Vector4 _TitleColor = new Vector4(1f, 0.85f, 0.6f, 1);
    Vector4 _LogColor = new Vector4(0.3f, 0.9f, 1, 1);

    //查找shader中对应的属性
    public void FindProperties(MaterialProperty[] props)
    {
        _UseCustomdata = FindProperty("_UseCustomdata", props);

        _Color = FindProperty("_Color", props);
        _MainTexture = FindProperty("_MainTexture", props);
        _MainUV = FindProperty("_MainUV", props);
        _UVAnimation = FindProperty("_UVAnimation", props);
        _Loop = FindProperty("_Loop", props);

        _UseDissolve = FindProperty("_UseDissolve", props);
        _EdgeColor = FindProperty("_EdgeColor", props);
        _DissolveMap = FindProperty("_DissolveMap", props);
        _DissolveUV = FindProperty("_DissolveUV", props);
        _Clip = FindProperty("_Clip", props);
        _EdgeRange = FindProperty("_EdgeRange", props);
        _EnableTwist = FindProperty("_EnableTwist", props);

        _UseMask = FindProperty("_UseMask", props);
        _MaskMap = FindProperty("_MaskMap", props);
        _MaskUV = FindProperty("_MaskUV", props);

        _UseTwist = FindProperty("_UseTwist", props);
        _TwistMap = FindProperty("_TwistMap", props);
        _TwistUV = FindProperty("_TwistUV", props);
        _TwistStrength = FindProperty("_TwistStrength", props);

        _UseRim = FindProperty("_UseRim", props);
        _ApplyAlpha = FindProperty("_ApplyAlpha", props);
        _FresnelColor = FindProperty("_FresnelColor", props);
        _FresnelRange = FindProperty("_FresnelRange", props);

        _ZWrite = FindProperty("_ZWrite", props);
        _ZTest = FindProperty("_ZTest", props);
        _Cull = FindProperty("_Cull", props);
    }
    //当材质从其他shader切换到此shader时执行
    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
    {
        base.AssignNewShaderToMaterial(material, oldShader, newShader);
    }

    //基础设置
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        TargetMat = materialEditor.target as Material;
        _Editor = materialEditor;
        //_Editor.PropertiesDefaultGUI(properties);
        //使用默认UI宽度
        EditorGUIUtility.labelWidth = 0f;
        //初始化属性
        FindProperties(properties);
        //画各属性界面
        MainTexture();
        Dissolve();
        Mask();
        Twist();
        Rim();
        CustomData();
        EditorGUILayout.Space(20);
        _Editor.ShaderProperty(_ZWrite, "Z Write");
        _Editor.ShaderProperty(_ZTest, "Z Test");
        BlendType();
        _Editor.ShaderProperty(_Cull, "Cull");
        _Editor.RenderQueueField();
        _Editor.EnableInstancingField();
    }

    //主贴图
    private void MainTexture()
    {
        _Editor.TexturePropertySingleLine(new GUIContent("主帖图"), _MainTexture, _Color);
        GUI.color = _TitleColor;
        _Editor.ShaderProperty(_UVAnimation, "开启自定义UV");
        GUI.color = Color.white;
        if (_UVAnimation.floatValue == 1)
        {
            _MainTextureLog = EditorGUILayout.Foldout(_MainTextureLog, "说明");
            if (_MainTextureLog)
            {
                GUI.color = _LogColor;
                GUILayout.Label("- XY控制缩放，ZW控制位移");
                GUILayout.Label("- 开启 '循环UV动画' 后，输入值控制位移速度,关闭以后控制位移距离");
                GUILayout.Label("- 使用CustomData可控制UV，详见CustomData说明");
                GUI.color = Color.white;
                EditorGUILayout.Space();
            }
            _Editor.ShaderProperty(_Loop, "循环UV动画");
            _Editor.ShaderProperty(_MainUV, "UV");
        }
    }

    //溶解
    private void Dissolve()
    {
        GUI.color = _TitleColor;
        _Editor.ShaderProperty(_UseDissolve, "溶解");
        GUI.color = Color.white;
        if (_UseDissolve.floatValue == 1)
        {
            _DissolveLog = EditorGUILayout.Foldout(_DissolveLog, "说明");
            if (_DissolveLog)
            {
                GUI.color = _LogColor;
                GUILayout.Label("- 贴图只使用了r通道，不支持带透明的贴图，彩色贴图只识别r通道");
                GUILayout.Label("- XY控制缩放，ZW控制UV移动速度");
                GUILayout.Label("- 颜色属性用于控制溶解边缘颜色");
                GUILayout.Label("- 边缘宽度同时控制边缘柔和度和边缘宽度，数值越小边缘越硬");
                GUILayout.Label("- 使用CustomData可控制边缘宽度，溶解率，UV流动，详见CustomData说明");
                GUI.color = Color.white;
                EditorGUILayout.Space();
            }
            _Editor.TexturePropertySingleLine(new GUIContent("溶解贴图"), _DissolveMap, _EdgeColor);
            _Editor.ShaderProperty(_DissolveUV, "UV");
            _Editor.ShaderProperty(_Clip, "溶解幅度");
            _Editor.ShaderProperty(_EdgeRange, "边缘宽度");
            _Editor.ShaderProperty(_EnableTwist,"受扭曲影响");
            EditorGUILayout.Space();
        }
    }

    //遮罩
    private void Mask()
    {
        GUI.color = _TitleColor;
        _Editor.ShaderProperty(_UseMask, "遮罩");
        GUI.color = Color.white;
        if (_UseMask.floatValue == 1)
        {
            _MaskLog = EditorGUILayout.Foldout(_MaskLog, "说明");
            if (_MaskLog)
            {
                GUI.color = _LogColor;
                GUILayout.Label("- 贴图只使用了r通道，不支持带透明的贴图，彩色贴图只识别r通道");
                GUILayout.Label("- XY控制缩放，ZW控制UV偏移");
                GUILayout.Label("- 没有使用CustomData");
                GUI.color = Color.white;
                EditorGUILayout.Space();
            }
            _Editor.TexturePropertySingleLine(new GUIContent("遮罩贴图"), _MaskMap);
            _Editor.ShaderProperty(_MaskUV, "UV");
            EditorGUILayout.Space();
        }
    }

    //扭曲
    private void Twist()
    {
        GUI.color = _TitleColor;
        _Editor.ShaderProperty(_UseTwist, "扭曲");
        GUI.color = Color.white;
        if (_UseTwist.floatValue == 1)
        {
            _TwistLog = EditorGUILayout.Foldout(_TwistLog, "说明");
            if (_TwistLog)
            {
                GUI.color = _LogColor;
                GUILayout.Label("- 贴图只使用了r通道，不支持带透明的贴图，彩色贴图只识别r通道");
                GUILayout.Label("- XY控制缩放，ZW控制UV移动速度");
                GUILayout.Label("- 没有使用CustomData");
                GUI.color = Color.white;
                EditorGUILayout.Space();
            }
            _Editor.TexturePropertySingleLine(new GUIContent("扭曲贴图"), _TwistMap);
            _Editor.ShaderProperty(_TwistUV, "UV");
            _Editor.ShaderProperty(_TwistStrength, "扭曲强度");
            EditorGUILayout.Space();
        }
    }

    //边缘光
    private void Rim()
    {
        GUI.color = _TitleColor;
        _Editor.ShaderProperty(_UseRim, "菲尼尔");
        GUI.color = Color.white;
        if (_UseRim.floatValue == 1)
        {
            _RimLog = EditorGUILayout.Foldout(_RimLog, "说明");
            if (_RimLog)
            {
                GUI.color = _LogColor;
                GUILayout.Label("- 支持HDR颜色");
                GUILayout.Label("- 透明度属性无效，用颜色明暗控制透明度");
                GUILayout.Label("- 边缘宽度数值越大，宽度越窄");
                GUILayout.Label("- 边缘宽度数值尽量不要太大");
                GUILayout.Label("- 勾选 “受透明度影响” 以后，边缘光会随着透明度变化而变化");
                GUILayout.Label("- 没有使用CustomData");
                GUI.color = Color.white;
                EditorGUILayout.Space();
            }
            _Editor.ShaderProperty(_ApplyAlpha, "受透明度影响");
            _Editor.ColorProperty(_FresnelColor, "边缘颜色");
            _Editor.ShaderProperty(_FresnelRange, "边缘宽度");
            EditorGUILayout.Space();
        }
    }

    //混合模式
    private void BlendType()
    {
        EditorGUI.BeginChangeCheck();
        int blenVar = TargetMat.GetFloat("_Dst") == 10 ? 0 : 1;
        _Blend = (BlendMode)EditorGUILayout.Popup("BlendMode", blenVar, Enum.GetNames(typeof(BlendMode)));
        if (EditorGUI.EndChangeCheck())
        {
            switch (_Blend)
            {
                case BlendMode.Alpha:
                    TargetMat.SetFloat("_Src", 5);
                    TargetMat.SetFloat("_Dst", 10);
                    break;
                case BlendMode.Add:
                    TargetMat.SetFloat("_Src", 5);
                    TargetMat.SetFloat("_Dst", 1);
                    break;
            }
        }
    }

    //使用CustomData
    private void CustomData()
    {
        GUI.color = _TitleColor;
        _Editor.ShaderProperty(_UseCustomdata, "使用粒子CustomData");
        GUI.color = Color.white;
        if (_UseCustomdata.floatValue == 1)
        {
            _CustomDataLog = EditorGUILayout.Foldout(_CustomDataLog, "说明");
            if (_CustomDataLog)
            {
                GUI.color = _LogColor;
                GUILayout.Label("- 开启此选项以后按照以下步骤操作");
                GUILayout.Label("- 1，在粒子renderer模块中开启 ‘custom vertex stream’");
                GUILayout.Label("- 2，在 ‘custom vertex stream’ 的列表中添加 ‘custom1.xyzw’");
                GUILayout.Label("- 3，在 ‘custom vertex stream’ 的列表中添加 ‘custom2.xy’");
                GUILayout.Label("- 4，打开粒子的 ‘Custom Data’选项");
                GUILayout.Label("- 5，将 ‘Custom1’ 的mode设置为Vector，Number of Componets设置为4");
                GUILayout.Label("- 6，将 ‘Custom2’ 的mode设置为Vector，Number of Componets设置为2");
                GUILayout.Label("--------------------------------------------------------------");
                GUILayout.Label("- 使用Custom1的X和Y来控制主帖图UV流动");
                GUILayout.Label("- 使用Custom1的Z来控制溶解率");
                GUILayout.Label("- 使用Custom1的W来控制溶解边缘宽度");
                GUILayout.Label("- 使用Custom2的X和Y来控制溶解帖图UV流动");
                EditorGUIUtility.labelWidth = 0f;
                GUI.color = Color.white;
                EditorGUILayout.Space();
            }
            EditorGUILayout.Space();
        }
    }
}