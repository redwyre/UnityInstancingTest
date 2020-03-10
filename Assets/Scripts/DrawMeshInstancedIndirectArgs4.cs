/// <summary>
/// Class used to structure the args buffer passed into DrawMeshInstancedIndirect.
/// </summary>
public class DrawMeshInstancedIndirectArgs4
{
    public const int Size = 4 * sizeof(uint);

    /// <summary> Layout of GPU args buffer. Do not change. </summary>
    public static class BufferIndex
    {
        public const int IndexCountPerInstance = 0;
        public const int InstanceCount = 1;
        public const int StartIndexLocation = 2;
        public const int BaseVertexLocation = 3;
    }

    public uint IndexCountPerInstance { get => Array[BufferIndex.IndexCountPerInstance]; set => Array[BufferIndex.IndexCountPerInstance] = value; }
    public uint InstanceCount { get => Array[BufferIndex.InstanceCount]; set => Array[BufferIndex.InstanceCount] = value; }
    public uint StartIndexLocation { get => Array[BufferIndex.StartIndexLocation]; set => Array[BufferIndex.StartIndexLocation] = value; }
    public uint BaseVertexLocation { get => Array[BufferIndex.BaseVertexLocation]; set => Array[BufferIndex.BaseVertexLocation] = value; }

    public readonly uint[] Array = new uint[4];
}

