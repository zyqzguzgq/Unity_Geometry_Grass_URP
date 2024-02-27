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
            };

            struct BladeData
            {
                float3 pos;
                float4 color;
            };

            StructuredBuffer<BladeData> _BladeDataBuffer;

            StructuredBuffer<float3> _Positions;
            uniform uint _BaseVertexIndex;
            uniform float4x4 _ObjectToWorld;
            uniform float _NumInstances;

            v2f vert(uint id : SV_VertexID , uint instanceID : SV_InstanceID)
            {
                v2f o;
                float3 pos = _Positions[id + _BaseVertexIndex];
                float4 wpos = mul(_ObjectToWorld, float4(pos , 1.0f)) + float4(instanceID , 0,0,0);
                o.positionCS = mul(UNITY_MATRIX_VP, wpos);
                o.col = float4( 1.f, 0.f, 0.0f, 0.0f);


                /*o.positionCS = TransformObjectToHClip(_BladeDataBuffer[id].pos);
                o.col = _BladeDataBuffer[id].color;*/

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return i.col;
            }
            ENDHLSL
        }
    }
}