@testset "Databases" begin
    server = InfluxServer("http://localhost:8086")

    create_database(server, "write_test")
    dbs, = list_databases(server)
    @test "write_test" in dbs[:name]

    t = time()
    measurements = [
        Measurement(
            "performance",
            Dict("cpu_load" => 0.1, "mem_free" => 123456),
            Dict("host" => "nureha"),
            t-1.5,
        ),
        Measurement(
            "performance",
            Dict("cpu_load" => 100.0, "mem_free" => 0),
            Dict("host" => "sadboi"),
            t-1.5,
        ),
        Measurement(
            "performance",
            Dict("cpu_load" => 0.2, "mem_free" => 234567),
            Dict("host" => "nureha"),
            t,
        ),
    ]

    InfluxDB.write(server, "write_test", measurements)
    cpu_load, = InfluxDB.query(server, "write_test", SELECT(;measurements=["performance"], condition=@querify(:host != "sadboi")))
    @test size(cpu_load) == (2,4)
    @test cpu_load[1, :cpu_load] == 0.1
    @test cpu_load[2, :cpu_load] == 0.2
    @test cpu_load[1, :mem_free] == 123456
    @test cpu_load[2, :mem_free] == 234567
    @test cpu_load[1, :host] == "nureha"
    @test cpu_load[2, :host] == "nureha"
end