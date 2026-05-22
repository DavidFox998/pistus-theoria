import { Router, type IRouter } from "express";
import healthRouter from "./health";
import storageRouter from "./storage";
import certificatesRouter from "./certificates";

const router: IRouter = Router();

router.use(healthRouter);
router.use(storageRouter);
router.use(certificatesRouter);

export default router;
