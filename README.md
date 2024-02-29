18/02/2024  加入了shadowCaster和Receive_Shadow,但还没给shadow做bias    

19/02/2024  shadow_bias 做完了，但没做环境光，看看有没有什么好的环境光的写法,修正了shadow strength，把diffsue的dot值从-1到1映射到0.7-1
            加了物体交互，但跟草地的交互还不是很完善，需要修正一下    
            
20/02/2024  修正了物体交互，用flowmap给草地加上了团簇的效果。flowmap要把贴图的srgb关掉   

29/02/2024  加两个buffer，一个是坐标输入buffer，一个是坐标输出buffer。计划是输入一个instance的每个顶点的坐标，然后输出要的总共数量的顶点坐标即为 instanceCount * pointNum