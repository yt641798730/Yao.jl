#################### Filter ######################
"""
    blockfilter(func, blk::AbstractBlock) -> Vector{AbstractBlock}
    blockfilter!(func, rgs::Vector, blk::AbstractBlock) -> Vector{AbstractBlock}

tree wise filtering for blocks.
"""
blockfilter(func, blk::AbstractBlock) = blockfilter!(func, Vector{AbstractBlock}([]), blk)

function blockfilter!(func, rgs::Vector, blk::CompositeBlock)
    if func(blk) push!(rgs, blk) end
    for block in subblocks(blk)
        blockfilter!(func, rgs, block)
    end
    rgs
end

blockfilter!(func, rgs::Vector, blk::PrimitiveBlock) = func(blk) ? push!(rgs, blk) : rgs
function blockfilter!(func, rgs::Vector, blk::AbstractContainer)
    func(blk) && push!(rgs, blk)
    blockfilter!(func, rgs, block(blk))
end

export traverse

"""
    traverse(blk; algorithm=:DFS) -> BlockTreeIterator

Returns an iterator that traverse through the block tree.
"""
traverse(root; algorithm=:DFS) = BlockTreeIterator(algorithm, root)

# TODO: add depth
export BlockTreeIterator

"""
    BlockTreeIterator{BT}

Iterate through the whole block tree with breadth first search.
"""
struct BlockTreeIterator{Algorithm, BT <: AbstractBlock}
    root::BT
end

BlockTreeIterator(Algorithm::Symbol, root::BT) where BT = BlockTreeIterator{Algorithm, BT}(root)

## Breadth First Search
function iterate(it::BlockTreeIterator{:BFS}, st = (q = Queue(AbstractBlock); enqueue!(q, itr.root)) )
    if isempty(st)
        nothing
    else
        node = dequeue!(st)
        enqueue_parent!(st, node)
        node, st
    end
end

function enqueue_parent!(queue::Queue, blk::AbstractContainer)
    enqueue!(queue, blk |> block)
    queue
end

function enqueue_parent!(queue::Queue, blk::CompositeBlock)
    for each in subblocks(blk)
        enqueue!(queue, each)
    end
    queue
end

function enqueue_parent!(queue::Queue, blk::AbstractBlock)
    queue
end

# Depth First Search
function iterate(it::BlockTreeIterator{:DFS}, st = AbstractBlock[it.root])
    if isempty(st)
        nothing
    else
        node = pop!(st)
        append!(st, Iterators.reverse(subblocks(node)))
        node, st
    end
end

#################### Expect and Measure ######################
"""
    expect(op::AbstractBlock, reg::AbstractRegister{B}) -> Vector
    expect(op::AbstractBlock, dm::DensityMatrix{B}) -> Vector

expectation value of an operator.
"""
function expect end

#expect(op::AbstractBlock, reg::AbstractRegister) = sum(conj(reg |> statevec) .* (apply!(copy(reg), op) |> statevec), dims=1) |> vec
#expect(op::AbstractBlock, reg::AbstractRegister{1}) = reg'*apply!(copy(reg), op)
expect(op::AbstractBlock, reg::AbstractRegister) = reg'*apply!(copy(reg), op)

expect(op::MatrixBlock, dm::DensityMatrix) = mapslices(x->sum(mat(op).*x)[], dm.state, dims=[1,2]) |> vec
expect(op::MatrixBlock, dm::DensityMatrix{1}) = sum(mat(op).*dropdims(dm.state, dims=3))

################### AutoDiff Circuit ###################
export autodiff, gradient, loss_expect!, loss_Z1!
"""
    gradient(U::AbstractBlock, δ::AbstractRegister)

get the (part) gradient ∂f/∂ψ*⋅∂ψ*/∂θ, given ∂f/∂ψ*.
"""
function gradient(U::AbstractBlock, δ::AbstractRegister)
    δ |> U'
    local grad = Float64[]
    blockfilter(U) do x
        x isa Diff && push!(grad, x.grad)
        false
    end
    grad
end

autodiff(block::Rotor{N}) where N = Diff(block)
# control, repeat, kron, roller and Diff can not propagate.
autodiff(block::AbstractBlock) = block
function autodiff(blk::Union{ChainBlock, Roller, Sequential})
    chsubblocks(blk, autodiff.(subblocks(blk)))
end

"""
    loss_expect(circuit::AbstractBlock, op::AbstractBlock) -> Function

Return function "loss!(ψ, θ) -> Vector"
"""
function loss_expect!(circuit::AbstractBlock, op::AbstractBlock)
    N = nqubits(circuit)
    function loss!(ψ::AbstractRegister, θ::Vector)
        params = parameters(circuit)
        dispatch!(circuit, θ)
        ψ |> circuit
        dispatch!!(circuit, params)
        expect(op, ψ)
    end
end

"""
    loss_Z1!(circuit::AbstractBlock; ibit::Int=1) -> Function

Return the loss function f = <Zi> (means measuring the ibit-th bit in computation basis).
"""
loss_Z1!(circuit::AbstractBlock; ibit::Int=1) = loss_expect!(circuit, put(nqubits(circuit), ibit=>Z))
