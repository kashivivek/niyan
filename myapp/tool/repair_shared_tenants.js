const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({ projectId: 'niyan-e2e4e' });
const db = getFirestore();

async function getAllDocs(collection) {
  const snapshot = await db.collection(collection).get();
  return snapshot.docs;
}

async function main() {
  const properties = await getAllDocs('properties');
  const currentTenantByUnitId = new Map();
  const currentUnitByTenantId = new Map();

  for (const property of properties) {
    const units = await property.ref.collection('units').get();
    for (const unit of units.docs) {
      const data = unit.data();
      const tenantId = data.currentTenantId;
      if (typeof tenantId !== 'string' || tenantId.length === 0) continue;

      const assignment = {
        tenantId,
        propertyId: property.id,
        unitId: unit.id,
        unitNumber: data.unitNumber || '',
      };
      currentTenantByUnitId.set(unit.id, assignment);
      currentUnitByTenantId.set(tenantId, assignment);
    }
  }

  let batch = db.batch();
  let pendingWrites = 0;
  let repairedTenants = 0;
  let repairedRentRecords = 0;
  let repairedTransactions = 0;

  async function commitIfNeeded() {
    if (pendingWrites === 500) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
  }

  for (const tenant of await getAllDocs('tenants')) {
    const assignment = currentUnitByTenantId.get(tenant.id);
    if (!assignment) continue;

    const data = tenant.data();
    if (data.propertyId !== assignment.propertyId ||
        data.assignedUnitId !== assignment.unitId ||
        data.isAssignedToUnit !== true) {
      batch.update(tenant.ref, {
        propertyId: assignment.propertyId,
        assignedUnitId: assignment.unitId,
        isAssignedToUnit: true,
      });
      pendingWrites++;
      repairedTenants++;
      await commitIfNeeded();
    }
  }

  for (const rentRecord of await getAllDocs('rentRecords')) {
    const data = rentRecord.data();
    const assignment = currentTenantByUnitId.get(data.unitId);
    if (!assignment) continue;

    const updates = {};
    if (data.tenantId !== assignment.tenantId) updates.tenantId = assignment.tenantId;
    if (data.propertyId !== assignment.propertyId) updates.propertyId = assignment.propertyId;
    if (data.unitId !== assignment.unitId) updates.unitId = assignment.unitId;

    if (Object.keys(updates).length > 0) {
      batch.update(rentRecord.ref, updates);
      pendingWrites++;
      repairedRentRecords++;
      await commitIfNeeded();
    }
  }

  for (const transaction of await getAllDocs('transactions')) {
    const data = transaction.data();
    const assignment = currentTenantByUnitId.get(data.unitId);
    if (!assignment) continue;

    const updates = {};
    if (data.propertyId !== assignment.propertyId) updates.propertyId = assignment.propertyId;
    if (data.unitId !== assignment.unitId) updates.unitId = assignment.unitId;
    if (Object.keys(updates).length > 0) {
      batch.update(transaction.ref, updates);
      pendingWrites++;
      repairedTransactions++;
      await commitIfNeeded();
    }
  }

  if (pendingWrites > 0) await batch.commit();
  console.log(`Repaired ${repairedTenants} tenants, ${repairedRentRecords} rent records, and ${repairedTransactions} transactions.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
