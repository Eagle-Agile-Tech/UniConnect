import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import VerificationPage from "./components/verification/page";
import IdVerificationPage from "./components/verification/verification";
import VerificationWithEmail from "./components/verification/vemail";
import InstitutionVerification from "./components/verification/instverifay";


export default function Verification() {
    return (
        <Routes>
            <Route index element={<VerificationPage />} />
            <Route path="verification-overview" element={<VerificationPage />} />
            <Route path="id-verification" element={<IdVerificationPage />} />
            <Route path="verified-email" element={<VerificationWithEmail />} />
            <Route path="Institution-Verification-" element={<InstitutionVerification />} />
            <Route path="Institution-Verification" element={<InstitutionVerification />} />

            <Route path="*" element={<Navigate to="verification-overview" replace />} />
        </Routes>
    );
}
