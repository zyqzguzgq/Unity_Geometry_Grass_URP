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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            float3 _LightDirection;

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 posWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float2 uv : TEXCOORD1;
            };

            struct BladeData
            {
                float3 pos;
                float4 color;
            };

            StructuredBuffer<BladeData> _BladeDataBuffer;

            StructuredBuffer<float3> _OutPosBuffer;
            StructuredBuffer<float3> _BladeNormalWSBuffer;

            StructuredBuffer<float3> _Positions;

            StructuredBuffer<float2> _UV;

            uniform uint _BaseVertexIndex;
            uniform float4x4 _ObjectToWorld;
            uniform float _NumInstances;
            uniform int _PointNum;
            uniform float _Interval;
            uniform float4 _BottomColor;
            uniform float4 _TopColor;
            uniform int _FiedWidth;

            v2f vert(uint id : SV_VertexID , uint instanceID : SV_InstanceID)
            {
                v2f o;
                //float3 pos = _Positions[id + _BaseVertexIndex];
                o.posWS = _OutPosBuffer[id + instanceID * _PointNum];
                o.normalWS = _BladeNormalWSBuffer[id + instanceID * _PointNum];
                float BladePosX = instanceID % _FiedWidth * _Interval;
                float BladePosZ = instanceID / _FiedWidth * _Interval;
                float4 wpos = float4(o.posWS , 1.0f) ;
                o.positionCS = mul(UNITY_MATRIX_VP, wpos);
                o.uv = _UV[id + _BaseVertexIndex];


                //o.positionCS = TransformObjectToHClip(_BladeDataBuffer[id].pos);
                

                return o;
            }

            float4 frag(v2f i,half facing : VFACE) : SV_Target
            {
                Light light = GetMainLight(TransformWorldToShadowCoord(i.posWS));
				float3 normal = facing > 0 ? i.normalWS : -i.normalWS;
                
				normal = normalize(normal);
                float4 finalColor = lerp(_BottomColor,_TopColor,i.uv.y);
                float4 lightCol = float4(light.color,1) ;
				float3 diffuse = (lerp(0.7,1,dot(normal , _LightDirection))) * lightCol.xyz;
                return finalColor * float4(diffuse,1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
			
            #pragma fragment frag
			

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
			
			
            // -------------------------------------
            // Includes
            
            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 posWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float2 uv : TEXCOORD1;
            };


            StructuredBuffer<float3> _OutPosBuffer;
            StructuredBuffer<float3> _BladeNormalWSBuffer;

            StructuredBuffer<float3> _Positions;

            StructuredBuffer<float2> _UV;

            uniform uint _BaseVertexIndex;
            uniform float4x4 _ObjectToWorld;
            uniform float _NumInstances;
            uniform int _PointNum;
            uniform float _Interval;
            uniform float4 _BottomColor;
            uniform float4 _TopColor;
            uniform int _FiedWidth;


            v2f vert(uint id : SV_VertexID , uint instanceID : SV_InstanceID)
            {
                v2f o;
                //float3 pos = _Positions[id + _BaseVertexIndex];
                o.posWS = _OutPosBuffer[id + instanceID * _PointNum];
                o.normalWS = _BladeNormalWSBuffer[id + instanceID * _PointNum];
                float BladePosX = instanceID % _FiedWidth * _Interval;
                float BladePosZ = instanceID / _FiedWidth * _Interval;
                float4 wpos = float4(o.posWS , 1.0f) ;
                o.positionCS = mul(UNITY_MATRIX_VP, wpos);
                o.uv = _UV[id + _BaseVertexIndex];


                //o.positionCS = TransformObjectToHClip(_BladeDataBuffer[id].pos);
                

                return o;
            }
            
			float4 frag(v2f i):SV_TARGET
			{
				return 0;
			}
            ENDHLSL
        }
    }
}