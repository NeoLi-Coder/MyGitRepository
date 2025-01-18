namespace CatlikeCodingFS.Basics1

open System
open Godot
open Godot.Collections

[<AbstractClass>]
type GpuGraphFS() =
    inherit Node3D()

    // 切记：对于 Tool 的 _Process 必须引入一个 bool 变量用 if 分支控制编译中间、之后都不报错
    let mutable ready = false
    let mutable duration = 0f
    let mutable transitioning = false
    let mutable transitionFunction = FunctionLibrary.FunctionName.Wave
    let mutable multiMeshIns: MultiMeshInstance3D = null

    let rd = RenderingServer.CreateLocalRenderingDevice()
    let mutable shader = Rid()
    let mutable pipeline = Rid()
    // 顶点字节数组，Vector3 数组被拆成 3 个 float32 数组，因为 Buffer.BlockCopy 只适用于基类数组。
    // （而且 ProceduralPlanet 那个项目在 GDScript 也是这样做的……）
    // 这里直接按 Resolution 最大值 1000 初始化数组大小，避免频繁分配新数组内存。
    let verticesBytes = Array.zeroCreate<byte> <| 3 * 1000 * 1000 * sizeof<float32>
    let uintParams = [| 10u; 0u |]
    let uintParamsBytes = Array.zeroCreate<byte> <| uintParams.Length * sizeof<uint>
    let floatParams = [| 0f; 0f; 0f |]

    let floatParamsBytes =
        Array.zeroCreate<byte> <| floatParams.Length * sizeof<float32>

    let mutable verticesBuffer = Rid()
    let uniformVertices = new RDUniform()
    let mutable uintParamsBuffer = Rid()
    let uniformUintParams = new RDUniform()
    let mutable floatParamsBuffer = Rid()
    let uniformFloatParams = new RDUniform()
    let mutable uniformSet = Rid()

    let mutable computeStartTime = 0uL
    let mutable outputReady = false
    let mutable output: float32 array = null

    abstract UpdateGraph: bool with get, set
    abstract Resolution: int with get, set
    abstract Function: FunctionLibrary.FunctionName with get, set
    abstract FunctionDuration: float32 with get, set
    abstract TransitionDuration: float32 with get, set
    abstract TransitionMode: TransitionMode with get, set

    member this.GetKernelIndex() =
        if transitioning then
            uint transitionFunction * 5u + uint this.Function
        else
            uint this.Function * 6u

    member this.PickNextFunction() =
        this.Function <-
            match this.TransitionMode with
            | TransitionMode.Cycle -> FunctionLibrary.getNextFunctionName this.Function
            | _ -> FunctionLibrary.getRandomFunctionNameOtherThan this.Function

    member this.InitializeComputeCode() =
        GD.Print "测试计算着色器，开始……"
        // 加载 GLSL 着色器
        let shaderFile =
            GD.Load("res://Shaders/Basics1/FunctionLibrary.glsl") :?> RDShaderFile

        let shaderSpirV = shaderFile.GetSpirV()
        shader <- rd.ShaderCreateFromSpirV shaderSpirV
        // 创建顶点存储缓冲区
        verticesBuffer <- rd.StorageBufferCreate(uint verticesBytes.Length, verticesBytes)
        uniformVertices.UniformType <- RenderingDevice.UniformType.StorageBuffer
        uniformVertices.Binding <- 0
        uniformVertices.AddId verticesBuffer
        // 创建流水线
        pipeline <- rd.ComputePipelineCreate shader
        let count = this.Resolution * this.Resolution
        output <- Array.zeroCreate<float32> <| count * 3
        this.RenderProcess()

    member this.RenderProcess() =
        if computeStartTime = 0uL then
            let count = this.Resolution * this.Resolution
            // 更新 uint 参数数组
            let kernelIdx = this.GetKernelIndex()
            uintParams[0] <- uint this.Resolution
            uintParams[1] <- kernelIdx
            Buffer.BlockCopy(uintParams, 0, uintParamsBytes, 0, uintParamsBytes.Length)
            // 更新 float 参数数组
            let step = 2f / float32 this.Resolution
            let time = float32 (Time.GetTicksMsec()) / 1000f
            let progress = duration / this.TransitionDuration
            floatParams[0] <- step
            floatParams[1] <- time
            floatParams[2] <- progress
            Buffer.BlockCopy(floatParams, 0, floatParamsBytes, 0, floatParamsBytes.Length)

            // 必须在此更新 uintParamsBuffer，floatParamsBuffer，否则放在初始化里仅创建一次的话，结果就会固定只重复第一次
            // 更新 uint 参数存储缓冲区
            uintParamsBuffer <- rd.StorageBufferCreate(uint uintParamsBytes.Length, uintParamsBytes)
            uniformUintParams.UniformType <- RenderingDevice.UniformType.StorageBuffer
            uniformUintParams.Binding <- 1
            uniformUintParams.ClearIds()
            uniformUintParams.AddId uintParamsBuffer
            // 更新 float 参数存储缓冲区
            floatParamsBuffer <- rd.StorageBufferCreate(uint floatParamsBytes.Length, floatParamsBytes)
            uniformFloatParams.UniformType <- RenderingDevice.UniformType.StorageBuffer
            uniformFloatParams.Binding <- 2
            uniformFloatParams.ClearIds()
            uniformFloatParams.AddId floatParamsBuffer

            // 开启新计算
            uniformSet <-
                rd.UniformSetCreate(
                    Array<RDUniform>([| uniformVertices; uniformUintParams; uniformFloatParams |]),
                    shader,
                    0u
                )

            let computeList = rd.ComputeListBegin()
            rd.ComputeListBindComputePipeline(computeList, pipeline)
            rd.ComputeListBindUniformSet(computeList, uniformSet, 0u)
            // 计算被舍入划分到大小和计算着色器 local_size 一致的大小的工作组
            rd.ComputeListDispatch(
                computeList,
                uint <| Mathf.CeilToInt(float32 count / 8f),
                uint <| Mathf.CeilToInt(float32 count / 8f),
                1u
            )

            rd.ComputeListEnd()
            // 提交到 GPU 和等待同步
            rd.Submit()
            computeStartTime <- Time.GetTicksMsec()

            async {
                rd.Sync()
                let outputBytes = rd.BufferGetData verticesBuffer

                if output.Length <> count * 3 then
                    output <- Array.zeroCreate<float32> <| count * 3

                Buffer.BlockCopy(outputBytes, 0, output, 0, output.Length * sizeof<float32>)
                outputReady <- true
            // this.UpdateMultiMesh() // 不知道为什么一起放进去就很慢…… 跨线程？还是闭包的原因吗？
            }
            |> Async.Start

    member this.UpdateMultiMesh() =
        if outputReady then
            let count = output.Length / 3 // 调整 Resolution 变化时 count 不能错误，不然 output 会数组越界
            let step = 2f / float32 this.Resolution // 容忍 step 在调整 Resolution 变化时计算错误
            let mutable anyChange = false

            if count > 0 then
                let scale = Vector3.One * step

                if multiMeshIns.Multimesh.InstanceCount <> count then
                    multiMeshIns.Multimesh.InstanceCount <- count
                // 这里因为没法一次性把数组写进去，导致耗时还是卡在这里了…… 分辨率 100 以上就有点卡了
                for i in 0 .. count - 1 do
                    let pos = Vector3(output[i * 3], output[i * 3 + 1], output[i * 3 + 2])
                    let trans = Transform3D(Basis.Identity.Scaled scale, pos)

                    if trans <> multiMeshIns.Multimesh.GetInstanceTransform i then
                        anyChange <- true
                        multiMeshIns.Multimesh.SetInstanceTransform(i, trans)

            GD.Print $"测试计算着色器，结束…… 修改：{anyChange}，耗时 {Time.GetTicksMsec() - computeStartTime} ms"
            computeStartTime <- 0uL
            outputReady <- false

    override this._Ready() =
        // 必须在代码里初始化 MultiMeshInstance3D 节点，不然场景里面既有的节点会被持久化
        // 否则 .tscn 将会包含了那些变化的 Transform 数组，一方面会很大，而且另一方面每次运行后都会被更新。其实完全没必要保存
        // （此外还少了一个 Godot 4.3 /scene/resources/multimesh.cpp:309 ERR_FAIL_COND(instance_count > 0); 的报错）
        multiMeshIns <- new MultiMeshInstance3D()
        multiMeshIns.Multimesh <- new MultiMesh()
        multiMeshIns.Multimesh.SetTransformFormat(MultiMesh.TransformFormatEnum.Transform3D)
        multiMeshIns.Multimesh.Mesh <- GD.Load<BoxMesh>("res://Materials/Basics1/GraphPointMesh.tres")
        this.AddChild multiMeshIns
        // 初始化计算着色器
        transitionFunction <- this.Function // 使得第一次生成的图是指定的函数
        this.InitializeComputeCode()
        ready <- true

    override this._Process delta =
        if ready then
            this.UpdateMultiMesh()

            if this.UpdateGraph then
                duration <- duration + float32 delta

                if transitioning then
                    if duration >= this.TransitionDuration then
                        duration <- duration - this.TransitionDuration
                        transitioning <- false
                elif duration >= this.FunctionDuration then
                    duration <- duration - this.FunctionDuration
                    transitioning <- true
                    transitionFunction <- this.Function
                    this.PickNextFunction()

                this.RenderProcess()
