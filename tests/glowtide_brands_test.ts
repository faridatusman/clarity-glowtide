import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that brand registration works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('glowtide-brands', 'register-brand', [
        types.ascii("EcoFashion"),
        types.uint(85),
        types.uint(90)
      ], deployer.address)
    ]);
    
    // Registration should succeed for contract owner
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Non-owner registration should fail
    block = chain.mineBlock([
      Tx.contractCall('glowtide-brands', 'register-brand', [
        types.ascii("BadActor"),
        types.uint(50),
        types.uint(50)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(types.uint(100));
  },
});

Clarinet.test({
  name: "Test certification updates",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // First register a brand
    let block = chain.mineBlock([
      Tx.contractCall('glowtide-brands', 'register-brand', [
        types.ascii("GreenClothes"),
        types.uint(90),
        types.uint(95)
      ], deployer.address)
    ]);
    
    // Update certifications
    block = chain.mineBlock([
      Tx.contractCall('glowtide-brands', 'update-certifications', [
        types.uint(1),
        types.bool(true),
        types.bool(true),
        types.bool(false)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify certifications
    let certifications = chain.callReadOnlyFn(
      'glowtide-brands',
      'get-brand-certifications',
      [types.uint(1)],
      deployer.address
    );
    
    certifications.result.expectOk().expectSome();
  },
});

Clarinet.test({
  name: "Test brand verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Register brand
    let block = chain.mineBlock([
      Tx.contractCall('glowtide-brands', 'register-brand', [
        types.ascii("EthicalBrand"),
        types.uint(88),
        types.uint(92)
      ], deployer.address)
    ]);
    
    // Verify brand
    block = chain.mineBlock([
      Tx.contractCall('glowtide-brands', 'verify-brand', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Non-owner verification should fail
    block = chain.mineBlock([
      Tx.contractCall('glowtide-brands', 'verify-brand', [
        types.uint(1)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(types.uint(100));
  },
});