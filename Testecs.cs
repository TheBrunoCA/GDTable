using GDTable.addons.gd_table.csharp;
using Godot;
using System;
using System.Collections.Generic;

public partial class Testecs : Control
{
    GDTableCS table;
    List<User> data;
    List<ColumnDefinition> columns;

    public override void _Ready()
    {
        table = GetNode<GDTableCS>("%GDTableCS");
        data = new List<User>
        {
            new User
            {
                Name = "John Doe",
                Age = 25,
                Country = "USA",
                City = "New York",
                Phone = "123456789",
                PostalCode = "12345",
                Company = "ACME",
                Job = "Developer"
            },
            new User
            {
                Name = "Jane Doe",
                Age = 30,
                Country = "USA",
                City = "Los Angeles",
                Phone = "987654321",
                PostalCode = "54321",
                Company = "ACME",
                Job = "Designer"
            },
            new User
            {
                Name = "John Smith",
                Age = 35,
                Country = "UK",
                City = "London",
                Phone = "123123123",
                PostalCode = "11111",
                Company = "ACME",
                Job = "Manager"
            },
            new User
            {
                Name = "Jane Smith",
                Age = 40,
                Country = "UK",
                City = "Manchester",
                Phone = "321321321",
                PostalCode = "22222",
                Company = "ACME",
                Job = "CEO"
            },
        };
        columns = new List<ColumnDefinition>
        {
            new ColumnDefinition("Name", "Nome", true, true, true),
            new ColumnDefinition("Age", "Idade", true, true),
            new ColumnDefinition("Country", "Pais", true, true),
            new ColumnDefinition("City", "Cidade", true, true),
            new ColumnDefinition("Phone", "Telefone", true, true, true),
            new ColumnDefinition("PostalCode", "Cep", true, true),
            new ColumnDefinition("Company", "Empresa", true, true),
            new ColumnDefinition("Job", "Emprego", true, true, true),
        };

        table.SetColumnsDefinitions(columns);
        table.SetDataSource(data);
    }
}

public class User : GDTableObject
{
    public string Name { get; set; }
    public int Age { get; set; }
    public string Country { get; set; }
    public string City { get; set; }
    public string Phone { get; set; }
    public string PostalCode { get; set; }
    public string Company { get; set; }
    public string Job { get; set; }
}