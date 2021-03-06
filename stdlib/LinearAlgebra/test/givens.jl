# This file is a part of Julia. License is MIT: https://julialang.org/license

module TestGivens

using Test, LinearAlgebra, Random
using LinearAlgebra: mul1!, mul2!

# Test givens rotations
@testset for elty in (Float32, Float64, ComplexF32, ComplexF64)
    if elty <: Real
        raw_A = convert(Matrix{elty}, randn(10,10))
    else
        raw_A = convert(Matrix{elty}, complex.(randn(10,10),randn(10,10)))
    end
    @testset for A in (raw_A, view(raw_A, 1:10, 1:10))
        Ac = copy(A)
        R = LinearAlgebra.Rotation(LinearAlgebra.Givens{elty}[])
        for j = 1:8
            for i = j+2:10
                G, _ = givens(A, j+1, i, j)
                mul2!(G, A)
                mul1!(A, adjoint(G))
                mul2!(G, R)

                @test mul2!(G,Matrix{elty}(I, 10, 10)) == [G[i,j] for i=1:10,j=1:10]

                @testset "transposes" begin
                    @test copy(G')*G*Matrix(elty(1)I, 10, 10) ≈ Matrix(I, 10, 10)
                    @test copy(R')*(R*Matrix(elty(1)I, 10, 10)) ≈ Matrix(I, 10, 10)
                    @test_throws ErrorException transpose(G)
                    @test_throws ErrorException transpose(R)
                end
            end
        end
        @test_throws ArgumentError givens(A, 3, 3, 2)
        @test_throws ArgumentError givens(one(elty),zero(elty),2,2)
        G, _ = givens(one(elty),zero(elty),11,12)
        @test_throws DimensionMismatch mul2!(G, A)
        @test_throws DimensionMismatch mul1!(A, adjoint(G))
        @test abs.(A) ≈ abs.(hessfact(Ac).H)
        @test norm(R*Matrix{elty}(I, 10, 10)) ≈ one(elty)

        I10 = Matrix{elty}(I, 10, 10)
        G, _ = givens(one(elty),zero(elty),9,10)
        @test (G*I10)' * (G*I10) ≈ I10
        K, _ = givens(zero(elty),one(elty),9,10)
        @test (K*I10)' * (K*I10) ≈ I10

        @testset "Givens * vectors" begin
            if isa(A, Array)
                x = A[:, 1]
            else
                x = view(A, 1:10, 1)
            end
            G, r = givens(x[2], x[4], 2, 4)
            @test (G*x)[2] ≈ r
            @test abs((G*x)[4]) < eps(real(elty))
            @inferred givens(x[2], x[4], 2, 4)

            G, r = givens(x, 2, 4)
            @test (G*x)[2] ≈ r
            @test abs((G*x)[4]) < eps(real(elty))
            @inferred givens(x, 2, 4)

            G, r = givens(x, 4, 2)
            @test (G*x)[4] ≈ r
            @test abs((G*x)[2]) < eps(real(elty))
        end
    end
end

end # module TestGivens
