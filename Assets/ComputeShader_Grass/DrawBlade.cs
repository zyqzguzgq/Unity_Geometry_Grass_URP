using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using Unity.Collections;
using Unity.Mathematics;
using UnityEngine;

public class DrawBlade : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;
    public Mesh mesh;
    public Texture2D WindTexture;
    public float _WindStrengthFactor = 1f;
    public float _WindFrequency = 1f;

    public int fieldWidth = 100;

    private Vector3 moving_position;
    public Transform movingObjectTransform;
    public float ImpactRadius = 0.08f;
    
    [SerializeField, Unity.Collections.ReadOnly]
    public int mBladeCount ;
    [Range(0,2f)]
    public float interval = 0.2f;
    [System.Serializable]
    public struct BladeDatas
    {
        [Range(0,1)]
        public float BladeWidth;
        [Range(0,10)]
        public float BladeHeight;
        
        [Range(0,1)]
        public float BendRotationRandom;
        
        public float BendDownFactor;
        [Range(1f,1.5f)]
        public float Curve ;
        public float BendStrength ;
        public Color BottomColor;
        public Color TopColor;
    }

    public BladeDatas bladeData;
    
    
    GraphicsBuffer meshTriangles;
    GraphicsBuffer meshPositions;
    GraphicsBuffer meshUV;
    //GraphicsBuffer bufferWithArgs;
    ComputeBuffer bufferWithArgs;

    ComputeBuffer mBladeDataBuffer;
    ComputeBuffer mBladeOutPosBuffer;
    ComputeBuffer mBladeNormalWSBuffer;
    ComputeBuffer mBladeInPosBuffer;
    int kernelId;

    private int pointNum;

public struct BladeData 
{
    public Vector3 pos;
    public Color color;

}
    
    
    

    void Start() {
        //structÖÐÒ»¹²7¸öfloat£¬size=28
        int pointNum = mesh.vertices.Length;
        this.pointNum = pointNum;

        this.mBladeCount = fieldWidth * fieldWidth;
        
        
        mBladeDataBuffer = new ComputeBuffer(this.mBladeCount,4*(3+4));
        
        BladeData[] BladeDatas = new BladeData[mBladeCount];

        mBladeOutPosBuffer = new ComputeBuffer(mBladeCount *pointNum,   3 *4);

        Vector3[] Pos = new Vector3[mBladeCount * pointNum];

        mBladeNormalWSBuffer = new ComputeBuffer(mBladeCount *pointNum,   3 *4);
        Vector3[] NormalWS = new Vector3[mBladeCount * pointNum];

        mBladeInPosBuffer = new ComputeBuffer(pointNum ,  3 *4);

        

        mBladeDataBuffer.SetData(BladeDatas);
        mBladeOutPosBuffer.SetData(Pos);
        mBladeNormalWSBuffer.SetData(NormalWS);
        mBladeInPosBuffer.SetData(mesh.vertices);

        kernelId = computeShader.FindKernel("UpdateBlade");



        meshTriangles = new GraphicsBuffer(GraphicsBuffer.Target.Structured, mesh.triangles.Length, sizeof(int));
        meshTriangles.SetData(mesh.triangles);
        meshPositions = new GraphicsBuffer(GraphicsBuffer.Target.Structured, mesh.vertices.Length, 3 * sizeof(float));
        meshPositions.SetData(mesh.vertices);
        meshUV = new GraphicsBuffer(GraphicsBuffer.Target.Structured , mesh.uv.Length , 2 * sizeof(float));
        meshUV.SetData(mesh.uv);

        /*int[] args = new int[5] { 0, 0, 0, 0,0 };
        
        
        args[0] = pointNum;
        args[1] = mBladeCount;     
        args[2] = 0;
        args[3] = 0; 
        args[4] =0;*/
        
        
        bufferWithArgs = new ComputeBuffer(1,sizeof(int) *5,ComputeBufferType.IndirectArguments);
        bufferWithArgs.SetData(new int[]{meshTriangles.count , mBladeCount ,0,0,0});
    }

    void Update() {
        moving_position = movingObjectTransform.position;
       
        this.mBladeCount = fieldWidth * fieldWidth;

        ComputeShaderSetting(ref computeShader);
        

        RenderParams rp = new RenderParams(material);
        rp.worldBounds = new Bounds(Vector3.zero, 10000*Vector3.one); // use tighter bounds
        rp.matProps = new MaterialPropertyBlock();

        GraphicsShaderSetting(ref rp);
        

        //Graphics.RenderPrimitivesIndexed(rp, MeshTopology.Triangles, meshTriangles, meshTriangles.count, (int)mesh.GetIndexStart(0), mBladeCount);
        Graphics.DrawProceduralIndirect(
            rp.material,
            rp.worldBounds,
            MeshTopology.Triangles, // 假设我们以三角形拓扑渲染
            meshTriangles,
            bufferWithArgs,
            0, // argsOffset
            null, // 默认渲染到当前激活的摄像机
            rp.matProps, 
            UnityEngine.Rendering.ShadowCastingMode.On, // 开启阴影投射
            true // 允许接收阴影
            // 使用当前GameObject的层
        );
        
    }


    void OnDestroy() {
        mBladeDataBuffer.Release();
        mBladeDataBuffer.Dispose();
        mBladeOutPosBuffer.Release();
        mBladeOutPosBuffer.Dispose();
        mBladeInPosBuffer.Release();
        mBladeInPosBuffer.Dispose();
        mBladeNormalWSBuffer.Release();
        mBladeNormalWSBuffer.Dispose();


        meshTriangles?.Dispose();
        meshTriangles = null;
        meshPositions?.Dispose();
        meshPositions = null;
        meshUV?.Dispose();
        meshUV = null;
        bufferWithArgs?.Dispose();
        bufferWithArgs = null;
    }

    void ComputeShaderSetting(ref ComputeShader computeShader)
    {
        computeShader.SetBuffer(kernelId, "BladeBuffer", mBladeDataBuffer);
        computeShader.SetBuffer(kernelId, "BladeOutPosBuffer", mBladeOutPosBuffer);
        computeShader.SetBuffer(kernelId, "BladeNormalWSBuffer" , mBladeNormalWSBuffer);
        computeShader.SetBuffer(kernelId, "BladeInPosBuffer" , mBladeInPosBuffer);
        computeShader.SetTexture(kernelId, "_WindTexture" , WindTexture);
        computeShader.SetVector( "_ObjectPosition", transform.position);
        computeShader.SetInt("_FieldWidth", this.fieldWidth);
        computeShader.SetVector("_Moving_Position" , moving_position);
        computeShader.SetFloat("_ImpactRadius" , ImpactRadius);

        computeShader.SetInt("pointNum",this.pointNum);
        computeShader.SetFloat("_BladeWidth" , bladeData.BladeWidth);
        computeShader.SetFloat("_BladeHeight" , bladeData.BladeHeight);
        computeShader.SetFloat("_Interval" , this.interval);
        computeShader.SetFloat("_BendDownFactor" , bladeData.BendDownFactor);
        computeShader.SetFloat("_Curve" , bladeData.Curve);
        computeShader.SetFloat("_BendStrength" , bladeData.BendStrength);
        computeShader.SetFloat("_BendRotationRandom" , bladeData.BendRotationRandom);
        computeShader.SetFloat("_Time" , Time.time);
        computeShader.SetFloat("_WindStrengthFactor" , _WindStrengthFactor);
        computeShader.SetFloat("_WindFrequency" , _WindFrequency);
        computeShader.SetMatrix("_ObjectToWorld" , Matrix4x4.TRS(new Vector3(0, 0, 0), Quaternion.identity, new Vector3(100f , 100f , 100f)));
        
        computeShader.Dispatch(kernelId, mBladeCount /64, 1, 1);
    }

    void GraphicsShaderSetting(ref RenderParams rp)
    {
        rp.matProps.SetBuffer("_Positions", meshPositions);
        rp.matProps.SetBuffer("_BladeDataBuffer", mBladeDataBuffer);
        rp.matProps.SetBuffer("_OutPosBuffer" , mBladeOutPosBuffer);
        rp.matProps.SetBuffer("_BladeNormalWSBuffer" , mBladeNormalWSBuffer);
        rp.matProps.SetInt("_BaseVertexIndex", (int)mesh.GetBaseVertex(0));
        rp.matProps.SetMatrix("_ObjectToWorld", Matrix4x4.TRS(new Vector3(0, 0, 0), Quaternion.identity, new Vector3(100f, 100f, 100f)));
        rp.matProps.SetColor("_BottomColor" , bladeData.BottomColor);
        rp.matProps.SetColor("_TopColor" , bladeData.TopColor);

        rp.matProps.SetFloat("_NumInstances", 10.0f);
        rp.matProps.SetInt("_PointNum" , this.pointNum);
        rp.matProps.SetInt("_FiedWidth", this.fieldWidth);
        rp.matProps.SetFloat("_Interval" , interval);
        rp.matProps.SetBuffer("_UV" , meshUV);
    }
}