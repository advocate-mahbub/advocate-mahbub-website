export function allocateLand(totalLand, rows) {
  const land = Number(totalLand);

  if (!Number.isFinite(land) || land <= 0) {
    throw new RangeError("Total land must be greater than zero.");
  }

  const totalShareTil = rows.reduce(
    (sum, row) => sum + BigInt(row.shareTil),
    0n
  );

  if (totalShareTil <= 0n) {
    throw new RangeError(
      "Total listed share must be greater than zero."
    );
  }

  return rows.map((row) => {
    const shareTil = BigInt(row.shareTil);

    const allocationRatio =
      Number(shareTil) / Number(totalShareTil);

    const allocatedLand =
      land * allocationRatio;

    const absoluteRatio =
      Number(shareTil) / 76800;

    return {
      ...row,
      shareTil,
      allocationRatio,
      absoluteRatio,
      allocatedLand,
    };
  });
}
