using CatlikeCodingFS.Basics1;
using Godot;

namespace CatlikeCodingCSharp.Scenes.Basics1.BuildingGraph;

[Tool]
public partial class GpuGraph : GpuGraphFS
{
    // 需要忽略 IDE 省略 partial、_Ready 等的提示，必须保留它们
    [Export] public override bool UpdateGraph { get; set; }
    [Export(PropertyHint.Range, "10, 1000")]
    public override int Resolution { get; set; } = 10;

    [Export(PropertyHint.Range, "0, 2")] public override FunctionLibrary.FunctionName Function { get; set; }

    [Export(PropertyHint.Range, "0.1, 10000")]
    public override float FunctionDuration { get; set; } = 1f;

    [Export(PropertyHint.Range, "0.1, 10000")]
    public override float TransitionDuration { get; set; } = 1f;

    [Export] public override TransitionMode TransitionMode { get; set; }

    public override void _Ready() => base._Ready();
    public override void _Process(double delta) => base._Process(delta);
}