Shader "Unlit/BladeShader"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        cull off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
            #include "UnityIndirect.cginc"  

            struct v2f
            {
                float4 col : COLOR0;
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD1;
            };

            struct BladeData
            {
                float3 pos;
                float4 color;
            };

            StructuredBuffer<BladeData> _BladeDataBuffer;

            StructuredBuffer<float3> _Positions;

            StructuredBuffer<float2> _UV;

            uniform uint _BaseVertexIndex;
            uniform float4x4 _ObjectToWorld;
            uniform float _NumInstances;
            uniform float _Interval;

            v2f vert(uint id : SV_VertexID , uint instanceID : SV_InstanceID)
            {
                v2f o;
                float3 pos = _Positions[id + _BaseVertexIndex];
                float BladePosX = instanceID % 100 * _Interval;
                float BladePosZ = instanceID / 100 * _Interval;
                float4 wpos = mul(_ObjectToWorld, float4(pos , 1.0f)) + float4(BladePosX ,0,BladePosZ,0);
                o.positionCS = mul(UNITY_MATRIX_VP, wpos);
                o.uv = _UV[id + _BaseVertexIndex];
                o.col = float4( 1.f, 0.f, 0.0f, 0.0f);


                /*o.positionCS = TransformObjectToHClip(_BladeDataBuffer[id].pos);
                o.col = _BladeDataBuffer[id].color;*/

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 finalColor = lerp(float4(0,1,0,1),float4(0,0,1,1),i.uv.y);
                return finalColor;
            }
            ENDHLSL
        }
    }
}