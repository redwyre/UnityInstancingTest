#ifndef MINIMAP_INSTANCED_CORE_HLSL_INCLUDED
#define MINIMAP_INSTANCED_CORE_HLSL_INCLUDED

#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED

void vertInstancingSetup()
{
    unity_ObjectToWorld = worldMatrixBuffer[unity_InstanceID];
    
    // inverse transform matrix
    float3x3 w2oRotation;
    w2oRotation[0] = unity_ObjectToWorld[1].yzx * unity_ObjectToWorld[2].zxy - unity_ObjectToWorld[1].zxy * unity_ObjectToWorld[2].yzx;
    w2oRotation[1] = unity_ObjectToWorld[0].zxy * unity_ObjectToWorld[2].yzx - unity_ObjectToWorld[0].yzx * unity_ObjectToWorld[2].zxy;
    w2oRotation[2] = unity_ObjectToWorld[0].yzx * unity_ObjectToWorld[1].zxy - unity_ObjectToWorld[0].zxy * unity_ObjectToWorld[1].yzx;

    float det = dot(unity_ObjectToWorld[0].xyz, w2oRotation[0]);

    w2oRotation = transpose(w2oRotation);

    w2oRotation *= rcp(det);

    float3 w2oPosition = mul(w2oRotation, -unity_ObjectToWorld._14_24_34);

    unity_WorldToObject._11_21_31_41 = float4(w2oRotation._11_21_31, -unity_ObjectToWorld._14);
    unity_WorldToObject._12_22_32_42 = float4(w2oRotation._12_22_32, -unity_ObjectToWorld._24);
    unity_WorldToObject._13_23_33_43 = float4(w2oRotation._13_23_33, -unity_ObjectToWorld._34);
    unity_WorldToObject._14_24_34_44 = float4(w2oPosition, 1.0f);
}

#endif

// Unity's vertDeffered with modifications to offset vertices and to curve them
VertexOutputDeferred vertMinimapDeferred(VertexInput v)
{
    UNITY_SETUP_INSTANCE_ID(v);
    VertexOutputDeferred o;
    UNITY_INITIALIZE_OUTPUT(VertexOutputDeferred, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    // Eco
    //float3 pos = float3(unity_ObjectToWorld._14, unity_ObjectToWorld._24, unity_ObjectToWorld._34);

    //float4 offset = float4(CalculateWrappedOffset(pos), 0);

    float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
    //posWorld = posWorld + offset;
    //posWorld = curveWorldPos(posWorld);
    // end Eco

#if UNITY_REQUIRE_FRAG_WORLDPOS
#if UNITY_PACK_WORLDPOS_WITH_TANGENT
    o.tangentToWorldAndPackedData[0].w = posWorld.x;
    o.tangentToWorldAndPackedData[1].w = posWorld.y;
    o.tangentToWorldAndPackedData[2].w = posWorld.z;
#else
    o.posWorld = posWorld.xyz;
#endif
#endif

    // Eco
    // UnityObjectToClipPos broken appart so we can adjust the world position
    float4 worldPos4 = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
    //worldPos4 = worldPos4 + offset;
    //worldPos4 = curveWorldPos(worldPos4);
    o.pos = mul(UNITY_MATRIX_VP, worldPos4);
    // end UnityObjectToClipPos
    // end Eco

    o.tex = TexCoords(v);
    o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
    float3 normalWorld = UnityObjectToWorldNormal(v.normal);
#ifdef _TANGENT_TO_WORLD
    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
    o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
    o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
    o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
#else
    o.tangentToWorldAndPackedData[0].xyz = 0;
    o.tangentToWorldAndPackedData[1].xyz = 0;
    o.tangentToWorldAndPackedData[2].xyz = normalWorld;
#endif

    o.ambientOrLightmapUV = 0;
#ifdef LIGHTMAP_ON
    o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#elif UNITY_SHOULD_SAMPLE_SH
    o.ambientOrLightmapUV.rgb = ShadeSHPerVertex(normalWorld, o.ambientOrLightmapUV.rgb);
#endif
#ifdef DYNAMICLIGHTMAP_ON
    o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

#ifdef _PARALLAXMAP
    TANGENT_SPACE_ROTATION;
    half3 viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
    o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
    o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
    o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
#endif

    return o;
}

#endif // MINIMAP_INSTANCED_CORE_HLSL_INCLUDED