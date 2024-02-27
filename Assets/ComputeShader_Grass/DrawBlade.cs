using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawBlade : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;
    public Mesh mesh;

    GraphicsBuffer meshTriangles;
    GraphicsBuffer meshPositions;

    ComputeBuffer mBladeDataBuffer;
    const int mBladeCount = 20000;
    int kernelId;

    struct BladeData {
        public Vector3 pos;
        public Color color;
    }

    void Start() {
        //structÖÐÒ»¹²7¸öfloat£¬size=28
        mBladeDataBuffer = new ComputeBuffer(mBladeCount, 28);
        BladeData[] BladeDatas = new BladeData[mBladeCount];
        mBladeDataBuffer.SetData(BladeDatas);
        kernelId = computeShader.FindKernel("UpdateBlade");

        meshTriangles = new GraphicsBuffer(GraphicsBuffer.Target.Structured, mesh.triangles.Length, sizeof(int));
        meshTriangles.SetData(mesh.triangles);
        meshPositions = new GraphicsBuffer(GraphicsBuffer.Target.Structured, mesh.vertices.Length, 3 * sizeof(float));
        meshPositions.SetData(mesh.vertices);
    }

    void Update() {
        computeShader.SetBuffer(kernelId, "BladeBuffer", mBladeDataBuffer);
        computeShader.SetFloat("Time", Time.time);
        computeShader.Dispatch(kernelId, mBladeCount / 1000, 1, 1);
        material.SetBuffer("_BladeDataBuffer", mBladeDataBuffer);

        RenderParams rp = new RenderParams(material);
        rp.worldBounds = new Bounds(Vector3.zero, 10000*Vector3.one); // use tighter bounds
        rp.matProps = new MaterialPropertyBlock();
        rp.matProps.SetBuffer("_Positions", meshPositions);
        rp.matProps.SetInt("_BaseVertexIndex", (int)mesh.GetBaseVertex(0));
        rp.matProps.SetMatrix("_ObjectToWorld", Matrix4x4.TRS(new Vector3(-4.5f, 0, 0), Quaternion.identity, new Vector3(100f, 100f, 100f)));
        rp.matProps.SetFloat("_NumInstances", 10.0f);
        Graphics.RenderPrimitivesIndexed(rp, MeshTopology.Triangles, meshTriangles, meshTriangles.count, (int)mesh.GetIndexStart(0), 10);
    }

    void OnRenderObject() {
        material.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Points, mBladeCount);
    }

    void OnDestroy() {
        mBladeDataBuffer.Release();
        mBladeDataBuffer.Dispose();

        meshTriangles?.Dispose();
        meshTriangles = null;
        meshPositions?.Dispose();
        meshPositions = null;
    }
}