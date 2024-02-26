using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class moving_to_shader : MonoBehaviour
{
    

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_PositionMoving", transform.position);
    }
}
