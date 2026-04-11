import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import VerificationPage from "./components/verification/page";
import PendingVerification from "./components/verification/peanding";
import VerificationWithID from "./components/verification/vid";
import VerificationWithEmail from "./components/verification/vemail";
import UnVerified from "./components/verification/unverified";

export default function Verification() {
    return (
        <div className="min-h-screen bg-linear-to-br from-slate-50 via-blue-50 to-indigo-50
        dark:from-slate-900 dark:via-slate-800 dark:to-slate-900 transition-all duration-500">
            <div className="p-6 space-y-6">
                <Routes>
                    <Route path="/" element={<VerificationPage />} />
                    <Route path="verification-overview" element={<VerificationPage />} />
                    <Route path="pending-verification" element={<PendingVerification />} />
                    <Route path="unverified" element={<UnVerified />} />
                    <Route path="verified-id" element={<VerificationWithID />} />
                    <Route path="verified-email" element={<VerificationWithEmail />} />
                    <Route path="*" element={<Navigate to="" replace />} />
                </Routes>
            </div>
        </div>
    );
}
