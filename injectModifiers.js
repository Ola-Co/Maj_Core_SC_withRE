import { policyModifierGeneration } from "@thrackle-io/forte-rules-engine-sdk";

const modifiersPath = "contracts/RulesEngineClientCustom.sol";
const yourContract = "contracts/Maj.sol";

policyModifierGeneration("policy.json", modifiersPath, [yourContract]);