using System.Runtime.CompilerServices;
using Bicep.RpcClient;
using Bicep.Testing.Framework;

[assembly: DoNotParallelize]

namespace Backstage.Tests;

// Demo 6: assert on what Bicep *would* deploy. No Azure login, no deployment.
[TestClass]
public sealed class StorageTests
{
    private const string Subscription = "00000000-0000-0000-0000-000000000001";
    private const string ResourceGroup = "rg-backstage-test";

    private static PooledBicepClientFactory factory = null!;
    private static BicepTestHelper bicep = null!;

    [ClassInitialize]
    public static void Start(TestContext _)
    {
        // One Bicep CLI process, started once and reused by every test.
        factory = new PooledBicepClientFactory();
        bicep = new BicepTestHelper(factory);
    }

    [ClassCleanup]
    public static void Stop() => factory.Dispose();

    [TestMethod]
    [DataRow("dev")]
    [DataRow("prod")]
    public async Task Every_storage_account_is_locked_down(string env)
    {
        var snapshot = await Snapshot(env);

        var accounts = snapshot.GetArmResourceOfType("Microsoft.Storage/storageAccounts").ToList();
        Assert.HasCount(2, accounts);

        foreach (var account in accounts)
        {
            Assert.IsFalse(account.GetRequiredBoolProperty("/properties/allowBlobPublicAccess"), account.Name);
            Assert.IsTrue(account.GetRequiredBoolProperty("/properties/supportsHttpsTrafficOnly"), account.Name);
            Assert.AreEqual("TLS1_2", account.GetRequiredStringProperty("/properties/minimumTlsVersion"), account.Name);
        }
    }

    [TestMethod]
    public async Task Prod_is_zone_redundant()
    {
        var snapshot = await Snapshot("prod");

        foreach (var account in snapshot.GetArmResourceOfType("Microsoft.Storage/storageAccounts"))
        {
            Assert.AreEqual("Standard_ZRS", account.GetRequiredStringProperty("/sku/name"), account.Name);
        }
    }

    [TestMethod]
    [DataRow("dev")]
    [DataRow("prod")]
    public async Task Names_are_valid_and_land_in_the_right_resource_group(string env)
    {
        var snapshot = await Snapshot(env);

        foreach (var account in snapshot.GetArmResourceOfType("Microsoft.Storage/storageAccounts"))
        {
            // uniqueString() and take() are already evaluated: this is the real name.
            Assert.MatchesRegex($"^bsb(data|logs){env}[a-z0-9]+$", account.Name);
            Assert.IsLessThanOrEqualTo(24, account.Name.Length);
            Assert.StartsWith(
                $"/subscriptions/{Subscription}/resourceGroups/{ResourceGroup}/",
                account.GetRequiredStringProperty("/id"));
        }
    }

    private static async Task<SnapshotResult> Snapshot(string env)
    {
        var snapshot = await bicep.GetSnapshot(Cli, new SnapshotOptions
        {
            FilePath = Path.Combine(InfraFolder(), $"{env}.bicepparam"),
            SubscriptionId = Subscription,
            ResourceGroup = ResourceGroup,
            Location = "westeurope",
        });

        // Always check diagnostics first: evaluation problems can leave the snapshot incomplete.
        Assert.IsEmpty(snapshot.Diagnostics, string.Join(Environment.NewLine, snapshot.Diagnostics));
        return snapshot;
    }

    // Pinned CLI by default, so the result does not depend on what is installed on this machine.
    // Set BICEP_CLI_PATH to run the same tests against another build, for example the nightly.
    private static BicepClientConfiguration Cli =>
        Environment.GetEnvironmentVariable("BICEP_CLI_PATH") is { Length: > 0 } path
            ? new BicepClientConfiguration { ExistingCliPath = path }
            : new BicepClientConfiguration { BicepVersion = "0.49.2" };

    // Read the Bicep files straight from the source tree, so an edit shows up on the next run.
    private static string InfraFolder([CallerFilePath] string thisFile = "") =>
        Path.Combine(Path.GetDirectoryName(thisFile)!, "infra");
}
