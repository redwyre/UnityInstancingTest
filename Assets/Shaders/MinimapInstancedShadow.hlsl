#ifndef MINIMAP_INSTANCED_SHADOW_HLSL_INCLUDED
#define MINIMAP_INSTANCED_SHADOW_HLSL_INCLUDED


void vertMinimapShadowCaster(VertexInput v
    , out float4 opos : SV_POSITION
#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
    , out VertexOutputShadowCaster o
#endif
#ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
    , out VertexOutputStereoShadowCaster os
#endif
)
{
    UNITY_SETUP_INSTANCE_ID(v);
#ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(os);
#endif

    

    // Eco
    //TRANSFER_SHADOW_CASTER_NOPOS(o, opos)

    //float3 pos = float3(unity_ObjectToWorld._14, unity_ObjectToWorld._24, unity_ObjectToWorld._34);

    //float4 offset = float4(CalculateWrappedOffset(pos), 0);

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    //posWorld = posWorld + offset;
    //posWorld = curveWorldPos(posWorld);

#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
    #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
        o.vec = posWorld.xyz - _LightPositionRange.xyz;
    #endif

    // UnityObjectToClipPos broken appart so we can adjust the world position
    float4 worldPos4 = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
    //worldPos4 = worldPos4 + offset;
    //worldPos4 = curveWorldPos(worldPos4);
    opos = mul(UNITY_MATRIX_VP, worldPos4);
    // end UnityObjectToClipPos
#else
    // UnityClipSpaceShadowCasterPos broken appart to adjust world position
    float4 wPos = mul(unity_ObjectToWorld, v.vertex);
    //wPos = wPos + offset;
    //wPos = curveWorldPos(wPos);

    if (unity_LightShadowBias.z != 0.0)
    {
        float3 wNormal = UnityObjectToWorldNormal(v.normal);
        float3 wLight = normalize(UnityWorldSpaceLightDir(wPos.xyz));

        // apply normal offset bias (inset position along the normal)
        // bias needs to be scaled by sine between normal and light direction
        // (http://the-witness.net/news/2013/09/shadow-mapping-summary-part-1/)
        //
        // unity_LightShadowBias.z contains user-specified normal offset amount
        // scaled by world space texel size.

        float shadowCos = dot(wNormal, wLight);
        float shadowSine = sqrt(1 - shadowCos * shadowCos);
        float normalBias = unity_LightShadowBias.z * shadowSine;

        wPos.xyz -= wNormal * normalBias;
    }

    opos = mul(UNITY_MATRIX_VP, wPos);
    // end UnityClipSpaceShadowCasterPos

    opos = UnityApplyLinearShadowBias(opos);
#endif
    // end Eco


#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
        o.tex = TRANSFORM_TEX(v.uv0, _MainTex);

#ifdef _PARALLAXMAP
    TANGENT_SPACE_ROTATION;
    o.viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
#endif
#endif
}


#endif // MINIMAP_INSTANCED_SHADOW_HLSL_INCLUDED