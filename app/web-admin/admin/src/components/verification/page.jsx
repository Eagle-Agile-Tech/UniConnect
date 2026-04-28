import React, { useState } from 'react';
import Charts from './charts';
import VerificationChart from './verificationchart'
export default function VerificationPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <Charts />
      {/* VerificationChart (Full width below) */}
      <div className="xl:col-span-2 xl:w-[75%] w-full :mx-auto">
      <VerificationChart />
      </div>
      </div>
    );
    }
