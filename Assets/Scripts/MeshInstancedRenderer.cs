using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class MeshInstancedRenderer : MonoBehaviour
{
    private const int InstanceBlockCount = 1000;
    public const int SizeOfMatrix = 4 * 4 * 4;

    public const int SizeX = 10;
    public const int SizeY = 10;
    public const int SizeZ = 10;
    public const int SizeTotal = SizeX * SizeY * SizeZ;

    public Mesh mesh;
    public int subMeshIndex = 0;
    public Material material;
    public int kernelIndex = 0;

    public ComputeShader cullComputeShaderPrefab;
    private ComputeShader cullComputeShaderInstance;

    //private int kernelIndex;
    private readonly List<Matrix4x4> matrices = new List<Matrix4x4>(InstanceBlockCount);
    public bool dirty = true;
    private MaterialPropertyBlock materialPropertyBlock;
    private ComputeBuffer instanceBuffer;
    private ComputeBuffer argsBuffer;
    private ComputeBuffer culledInstanceBuffer;
    private DrawMeshInstancedIndirectArgs5 args = new DrawMeshInstancedIndirectArgs5();
    private Bounds infiniteBounds = new Bounds(Vector3.zero, Vector3.positiveInfinity);

    int WorldMatrixBufferId = Shader.PropertyToID("worldMatrixBuffer");

    // Computer shader
    int WorldMatrixBufferInputId = Shader.PropertyToID("worldMatrixBufferInput");
    int WorldMatrixBufferOutputId = Shader.PropertyToID("worldMatrixBufferOutput");
    Vector3 offset = new Vector3(-4, -4, -4);

    public void Start()
    {
        materialPropertyBlock = new MaterialPropertyBlock();
        instanceBuffer = new ComputeBuffer(InstanceBlockCount, SizeOfMatrix, ComputeBufferType.Structured);
        culledInstanceBuffer = new ComputeBuffer(InstanceBlockCount, SizeOfMatrix, ComputeBufferType.Append);
        culledInstanceBuffer.SetCounterValue(0);
        argsBuffer = new ComputeBuffer(1, DrawMeshInstancedIndirectArgs5.Size, ComputeBufferType.IndirectArguments);

        //cullComputeShaderInstance = Resources.Load<ComputeShader>("MinimapCull");
        //cullComputeShaderInstance = Instantiate<ComputeShader>(cullComputeShaderPrefab);
        cullComputeShaderInstance = cullComputeShaderPrefab;
        //kernelIndex = cullComputeShaderInstance.FindKernel("CullInstances");
        //kernelIndex = cullComputeShaderInstance.FindKernel("PassThrough");

        UpdateArgs();
    }

    public void OnDestroy()
    {
        instanceBuffer.Dispose();
        culledInstanceBuffer.Dispose();
        argsBuffer.Dispose();
    }

    private void LateUpdate()
    {
        if (dirty)
        {
            UpdateMatrices();
            UpdateArgs();
            dirty = false;
        }

        var layer = this.gameObject.layer;

        // FIXME SJS for some reason the culled buffer contents are not correct
        //material.SetBuffer(WorldMatrixBufferId, culledInstanceBuffer);
        //material.SetBuffer(WorldMatrixBufferId, instanceBuffer);

        materialPropertyBlock.SetBuffer(WorldMatrixBufferId, culledInstanceBuffer);

        RunCullShader();

        Graphics.DrawMeshInstancedIndirect(mesh, subMeshIndex, material, infiniteBounds, argsBuffer, 0, materialPropertyBlock, ShadowCastingMode.On, true, layer, null, LightProbeUsage.Off, null);
    }

    /// <summary> Ensure the instance buffer has a capacity >= count. It increases in multiples of <see cref="InstanceBlockCount"/> to reduce allocations. </summary>
    private void EnsureBufferCapacity(int count)
    {
        var desiredCount = instanceBuffer.count;
        while (desiredCount < count)
        {
            desiredCount += InstanceBlockCount;
        }

        if (instanceBuffer.count < desiredCount)
        {
            instanceBuffer.Dispose();
            instanceBuffer = new ComputeBuffer(desiredCount, SizeOfMatrix, ComputeBufferType.Structured);

            culledInstanceBuffer.Dispose();
            culledInstanceBuffer = new ComputeBuffer(desiredCount, SizeOfMatrix, ComputeBufferType.Append);
            culledInstanceBuffer.SetCounterValue(0);
        }
    }

    /// <summary> Generate a list of matrices for each view and upload into compute buffer. </summary>
    private void UpdateMatrices()
    {
        matrices.Clear();
        matrices.Capacity = Math.Max(matrices.Capacity, SizeTotal);

        for (int z = 0; z < SizeZ; ++z)
            for (int y = 0; y < SizeY; ++y)
                for (int x = 0; x < SizeX; ++x)
                {
                    var position = new Vector3(x, y, z) + offset;
                    var mat = Matrix4x4.Translate(position * 5);

                    matrices.Add(mat * transform.localToWorldMatrix);
                }

        EnsureBufferCapacity(matrices.Count);
        instanceBuffer.SetData(matrices);
    }

    private void UpdateArgs()
    {
        args.IndexCountPerInstance = mesh.GetIndexCount(subMeshIndex);
        args.InstanceCount = 0;
        //args.InstanceCount = SizeTotal;
        args.StartIndexLocation = mesh.GetIndexStart(subMeshIndex);
        args.BaseVertexLocation = mesh.GetBaseVertex(subMeshIndex);
        args.StartInstanceLocation = 0;
        
        argsBuffer.SetData(args.Array);
    }

    public void RunCullShader()
    {
        culledInstanceBuffer.SetCounterValue(0);

        cullComputeShaderInstance.SetBuffer(kernelIndex, WorldMatrixBufferInputId, instanceBuffer);
        cullComputeShaderInstance.SetBuffer(kernelIndex, WorldMatrixBufferOutputId, culledInstanceBuffer);

        cullComputeShaderInstance.Dispatch(kernelIndex, matrices.Count, 1, 1);

        ComputeBuffer.CopyCount(culledInstanceBuffer, argsBuffer, DrawMeshInstancedIndirectArgs5.BufferIndex.InstanceCount * sizeof(uint));

        var tempArgs = new uint[5];
        argsBuffer.GetData(tempArgs);
    }
}

