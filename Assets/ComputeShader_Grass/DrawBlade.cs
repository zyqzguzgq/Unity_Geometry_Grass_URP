using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DrawBlade : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;
    public Mesh mesh;

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
    }

    void Update() {
        computeShader.SetBuffer(kernelId, "BladeBuffer", mBladeDataBuffer);
        computeShader.SetFloat("Time", Time.time);
        computeShader.Dispatch(kernelId, mBladeCount / 1000, 1, 1);
        material.SetBuffer("_BladeDataBuffer", mBladeDataBuffer);
    }

    void OnRenderObject() {
        material.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Points, mBladeCount);
    }

    void OnDestroy() {
        mBladeDataBuffer.Release();
        mBladeDataBuffer.Dispose();
    }
}