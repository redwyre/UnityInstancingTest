Shader "Custom/InstancedMinimapMesh"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }

    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup

        StructuredBuffer<float4x4> worldMatrixBuffer;
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Cull Back
        ZTest LEqual
        ZWrite On

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" "DisableBatching" = "False" }

            CGPROGRAM
            #pragma target 5.0

            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma multi_compile _ MINIMAP_NO_CURVE

            #pragma vertex vertMinimapShadowCaster
            #pragma fragment fragShadowCaster

            #define UNITY_STANDARD_SIMPLE 1

            #include "UnityStandardShadow.cginc"
            #include "MinimapInstancedShadow.hlsl"
            ENDCG
        }

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma enable_d3d11_debug_symbols
            #pragma target 5.0
            #pragma exclude_renderers nomrt

            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma multi_compile _ MINIMAP_NO_CURVE

            #pragma vertex vertMinimapBase
            #pragma fragment fragBase

            #define UNITY_NO_FULL_STANDARD_SHADER 1

            #include "UnityStandardCoreForward.cginc"
            #include "MinimapInstancedCoreForward.hlsl"

            ENDCG
        }

        Pass
        {
            Name "DEFERRED"
            Tags { "LightMode" = "Deferred" }

            CGPROGRAM
            #pragma enable_d3d11_debug_symbols
            #pragma target 5.0
            #pragma exclude_renderers nomrt

            #pragma multi_compile_prepassfinal
            #pragma multi_compile_instancing
            #pragma multi_compile _ MINIMAP_NO_CURVE

            #pragma instancing_options procedural:vertInstancingSetup

            #pragma vertex vertMinimapDeferred
            #pragma fragment fragDeferred

            #define UNITY_STANDARD_SIMPLE 1

            #include "UnityStandardCore.cginc"
            #include "MinimapInstancedCore.hlsl"

            ENDCG
        }
    }
}
