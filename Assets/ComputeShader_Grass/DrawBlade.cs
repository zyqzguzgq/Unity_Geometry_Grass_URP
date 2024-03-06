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
    public Texture2D GrassToward;

    public int fieldWidth = 100;

    private Vector3 moving_position;
    public Transform movingObjectTransform;
    public float ImpactRadius = 0.08f;
    
    [SerializeField, Unity.Collections.ReadOnly]
    public int mBladeCount ;
    [Range(0,0.5f)]
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
        [Range(0f,10f)]
        public float Curve ;
        [Range(0,3f)]
        public float BendStrength ;
        public Color BottomColor;
        public Color TopColor;
    }

    public BladeDatas bladeData;
    
    
    GraphicsBuffer meshTriangles;
    GraphicsBuffer meshPositions;
    GraphicsBuffer meshUV;
    ComputeBuffer bufferWithArgs;

    ComputeBuffer mBladeDataBuffer;
    ComputeBuffer mBladeInPosBuffer;
    ComputeBuffer mCullingResultBuffer;

    Camera mainCamera;
    int kernelId;

    private int pointNum;

    Vector4[] planes;


    
    
    

    void Start() {
        //structÖÐÒ»¹²7¸öfloat£¬size=28
        int pointNum = mesh.vertices.Length;
        this.pointNum = pointNum;

        mainCamera = Camera.main;

        this.mBladeCount = fieldWidth * fieldWidth;
        
        mBladeDataBuffer = new ComputeBuffer(mBladeCount , pointNum * 3 * 4 *2);

        mBladeInPosBuffer = new ComputeBuffer(pointNum ,  3 *4);

        mCullingResultBuffer = new ComputeBuffer(mBladeCount , pointNum * 3 * 4 * 2 ,ComputeBufferType.Append);
        

        

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
        this.planes = CullTool.GetFrustumPlane(mainCamera);

        this.mBladeCount = fieldWidth * fieldWidth;
        mCullingResultBuffer.SetCounterValue(0);
        ComputeShaderSetting(ref computeShader);
        

        RenderParams rp = new RenderParams(material);
        rp.worldBounds = new Bounds(Vector3.zero, 10000*Vector3.one); // use tighter bounds
        rp.matProps = new MaterialPropertyBlock();
        

        GraphicsShaderSetting(ref rp);

        ComputeBuffer.CopyCount(mCullingResultBuffer ,bufferWithArgs,sizeof(int));

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
        mBladeInPosBuffer.Release();
        mBladeInPosBuffer.Dispose();
        mCullingResultBuffer.Release();
        mCullingResultBuffer.Dispose();



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
        computeShader.SetBuffer(kernelId ,"BladeDataBuffer" , mBladeDataBuffer);
        computeShader.SetBuffer(kernelId, "BladeInPosBuffer" , mBladeInPosBuffer);
        computeShader.SetBuffer(kernelId, "CullingResultsBuffer", mCullingResultBuffer);

        computeShader.SetVectorArray("planes", planes);
        computeShader.SetTexture(kernelId, "_WindTexture" , WindTexture);
        computeShader.SetTexture(kernelId,"_GrassToward",GrassToward);
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
        
        computeShader.Dispatch(kernelId, mBladeCount /640, 1, 1);
    }

    void GraphicsShaderSetting(ref RenderParams rp)
    {
        rp.matProps.SetBuffer("_Positions", meshPositions);
        rp.matProps.SetBuffer("_BladeDataBuffer",mBladeDataBuffer);
        rp.matProps.SetBuffer("_CullingResultBuffer" , mCullingResultBuffer);

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